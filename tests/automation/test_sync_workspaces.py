"""Exercise the real synchronizer against disposable local bare remotes."""
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from sync_workspaces import Synchronizer, SyncError, load_config, select_pairs
from sync_pre_push import validate

CONFIG = ROOT / ".github" / "sync-config.json"
LAB_README = ("# LAB — cueva\n\n> Rama temporal: `lab/cueva`\n"
              "> Rama oficial: `cueva`\n\nContenido operativo local.\n").encode()


class ConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.config = load_config(CONFIG)

    def invalid(self, config):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            path.write_text(json.dumps(config), encoding="utf-8")
            with self.assertRaises(SyncError):
                load_config(path)

    def test_pilot_and_six_mappings(self):
        self.assertEqual(self.config["enabled_sources"], ["cueva"])
        self.assertEqual(len(self.config["pairs"]), 6)

    def test_inverse_unknown_duplicate_and_operational_path_rejected(self):
        for key, value in [("repository", "other/repo"), ("schema_version", True),
                           ("operational_readme", "../README.md"),
                           ("local_ignore_line", "src/"),
                           ("enabled_sources", ["cueva", "cueva"]),
                           ("enabled_sources", ["lab/cueva"]), ("enabled_sources", [])]:
            with self.subTest(key=key, value=value):
                config = copy.deepcopy(self.config)
                config[key] = value
                self.invalid(config)
        config = copy.deepcopy(self.config)
        config["pairs"][2] = {"source": "lab/cueva", "destination": "cueva"}
        self.invalid(config)
        config = copy.deepcopy(self.config)
        config["unexpected"] = True
        self.invalid(config)

    def test_push_to_lab_or_disabled_owner_does_not_run(self):
        for ref in ("lab/cueva", "master", "poma", "untrusted"):
            self.assertEqual(select_pairs(self.config, "push", ref), [])
        self.assertEqual(select_pairs(self.config, "push", "cueva"), [self.config["pairs"][2]])

    def test_schedule_and_completed_master_select_enabled_only(self):
        for event in ("schedule", "workflow_run"):
            self.assertEqual(select_pairs(self.config, event), [self.config["pairs"][2]])

    def test_manual_disabled_pair_and_unknown_event_rejected(self):
        with self.assertRaises(SyncError):
            select_pairs(self.config, "workflow_dispatch", selection="poma")
        with self.assertRaises(SyncError):
            select_pairs(self.config, "pull_request")
        self.assertEqual(select_pairs(self.config, "workflow_dispatch", selection="todos"),
                         [self.config["pairs"][2]])

    def test_non_object_config_rejected(self):
        self.invalid([])
        self.invalid("cueva")

    def test_duplicate_json_key_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            path.write_text('{"schema_version": 1, "schema_version": 1}', encoding="utf-8")
            with self.assertRaises(SyncError):
                load_config(path)

    def test_cli_apply_outside_actions_rejected_before_network(self):
        env = os.environ.copy()
        for key in ("GITHUB_ACTIONS", "GITHUB_REPOSITORY", "SYNC_GITHUB_TOKEN"):
            env.pop(key, None)
        result = subprocess.run([sys.executable, "-B", str(ROOT / "scripts/sync_workspaces.py"),
                                 "run", "--config", str(CONFIG), "--source", "cueva", "--apply"],
                                env=env, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn(b"GitHub Actions", result.stderr)
        self.assertFalse(result.stdout)

    def test_cli_plan_writes_matrix_and_has_work(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "output"
            env = dict(os.environ, SYNC_EVENT="push", SYNC_REF="cueva", GITHUB_OUTPUT=str(output))
            result = subprocess.run([sys.executable, "-B", str(ROOT / "scripts/sync_workspaces.py"),
                                     "plan", "--config", str(CONFIG)], env=env, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            lines = output.read_text().splitlines()
            self.assertEqual(json.loads(lines[0].split("=", 1)[1]),
                             {"include": [self.config["pairs"][2]]})
            self.assertEqual(lines[1], "has_work=true")


class GitTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="sync-tests-")
        self.root = Path(self.temp.name)
        self.remote = self.root / "remote.git"
        self.remote.mkdir()
        self.env = os.environ.copy()
        for key in list(self.env):
            if key.startswith("GIT_"):
                self.env.pop(key)
        self.env.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        self.git("init", "--bare")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.base = self.commit([], {"README.md": b"Official README\n",
                                    ".gitignore": b"/frontend\n", "feature.txt": b"base\n"})
        self.source = self.base
        self.destination = self.commit([self.base], {"README.md": LAB_README,
                                                    ".gitignore": b"/frontend\n.stitch/\n",
                                                    "draft.txt": b"lab draft\n"})
        self.update("cueva", self.source)
        self.update("lab/cueva", self.destination)
        self.count = 0

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args, data=None):
        result = subprocess.run(["git", "-C", str(self.remote), *args], input=data,
                                env=self.env, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors="replace"))
        return result.stdout.decode().strip()

    def commit(self, parents, changes, message="Fixture", modes=None):
        self.git("read-tree", parents[0] if parents else "--empty")
        for path, content in changes.items():
            if content is None:
                self.git("update-index", "--index-info",
                         data=("0 " + "0" * 40 + "\t" + path + "\n").encode())
            else:
                oid = self.git("hash-object", "-w", "--stdin", data=content)
                mode = (modes or {}).get(path, "100644")
                self.git("update-index", "--add", "--cacheinfo", mode + "," + oid + "," + path)
        tree = self.git("write-tree")
        args = ["commit-tree", tree]
        for parent in parents:
            args.extend(["-p", parent])
        return self.git(*args, data=(message + "\n").encode())

    def update(self, branch, oid):
        self.git("update-ref", "refs/heads/" + branch, oid)

    def head(self, branch):
        return self.git("rev-parse", "refs/heads/" + branch)

    def advance(self, changes):
        self.source = self.commit([self.source], changes)
        self.update("cueva", self.source)

    def engine(self):
        self.count += 1
        return Synchronizer(self.root / str(self.count) / "objects.git", str(self.remote))

    def execute(self, **kwargs):
        original_source = self.head("cueva")
        result = self.engine().run("cueva", **kwargs)
        self.assertEqual(self.head("cueva"), original_source)
        return result

    def blocked(self, **kwargs):
        before = self.head("lab/cueva")
        with self.assertRaises(SyncError):
            self.engine().run("cueva", apply=True, **kwargs)
        self.assertEqual(self.head("lab/cueva"), before)

    def test_source_already_incorporated_no_commit(self):
        result = self.execute(apply=True)
        self.assertEqual(result["status"], "up_to_date")
        self.assertEqual(self.head("lab/cueva"), self.destination)

    def test_dry_run_has_no_external_effect(self):
        self.advance({"feature.txt": b"official update\n"})
        result = self.execute()
        self.assertEqual(result["status"], "dry_run")
        self.assertEqual(self.head("lab/cueva"), self.destination)

    def test_real_push_preserves_lab_readme_draft_and_new_official_ignore(self):
        self.advance({"feature.txt": b"official update\n", "README.md": b"New official README\n",
                      ".gitignore": b"/frontend\n/build\n"})
        result = self.execute(apply=True)
        self.assertEqual(result["status"], "published")
        new = self.head("lab/cueva")
        self.assertEqual(new, result["commit"])
        self.assertEqual(self.git("show", new + ":README.md").encode() + b"\n", LAB_README)
        self.assertEqual(self.git("show", new + ":.gitignore"), "/frontend\n/build\n.stitch/")
        self.assertEqual(self.git("show", new + ":draft.txt"), "lab draft")
        self.assertEqual(self.git("show", new + ":feature.txt"), "official update")
        self.assertEqual(self.git("rev-list", "--parents", "-n", "1", new).split()[1:],
                         [self.destination, self.source])

    def test_second_run_idempotent(self):
        self.advance({"feature.txt": b"update\n"})
        self.execute(apply=True)
        before = self.head("lab/cueva")
        self.assertEqual(self.execute(apply=True)["status"], "up_to_date")
        self.assertEqual(self.head("lab/cueva"), before)

    def test_compatible_changes_from_both_sides(self):
        self.destination = self.commit([self.destination], {"lab-feature.txt": b"local\n"})
        self.update("lab/cueva", self.destination)
        self.advance({"feature.txt": b"official\n"})
        self.execute(apply=True)
        self.assertEqual(self.git("show", "lab/cueva:lab-feature.txt"), "local")
        self.assertEqual(self.git("show", "lab/cueva:feature.txt"), "official")

    def test_functional_conflict_stops_without_writing(self):
        self.destination = self.commit([self.destination], {"feature.txt": b"local\n"})
        self.update("lab/cueva", self.destination)
        self.advance({"feature.txt": b"official\n"})
        self.blocked()

    def test_ignore_functional_conflict_not_hidden_by_exception(self):
        self.destination = self.commit([self.destination], {".gitignore": b"/local\n.stitch/\n"})
        self.update("lab/cueva", self.destination)
        self.advance({".gitignore": b"/official\n"})
        self.blocked()

    def test_missing_destination_is_not_created(self):
        self.git("update-ref", "-d", "refs/heads/lab/cueva")
        with self.assertRaises(SyncError):
            self.engine().run("cueva", apply=True)
        self.assertNotIn("refs/heads/lab/cueva", self.git("show-ref"))

    def test_missing_source_is_not_created(self):
        self.git("update-ref", "-d", "refs/heads/cueva")
        self.blocked()
        self.assertNotIn("refs/heads/cueva", self.git("show-ref"))

    def test_unrelated_histories_rejected(self):
        self.source = self.commit([], {"other.txt": b"unrelated\n"})
        self.update("cueva", self.source)
        self.blocked()

    def test_multiple_merge_bases_rejected(self):
        a = self.commit([self.base], {"a.txt": b"a\n"}, "A")
        b = self.commit([self.base], {"b.txt": b"b\n"}, "B")
        source = self.commit([a, b], {"b.txt": b"b\n"}, "merge AB")
        destination = self.commit([b, a], {"a.txt": b"a\n", "README.md": LAB_README}, "merge BA")
        self.update("cueva", source)
        self.update("lab/cueva", destination)
        self.blocked()

    def test_invalid_readme_and_symlink_rejected(self):
        for content, modes in [(b"Official file\n", {}), (b"README-other.md", {"README.md": "120000"})]:
            with self.subTest(content=content):
                dest = self.commit([self.destination], {"README.md": content}, modes=modes)
                self.update("lab/cueva", dest)
                self.blocked()

    def test_operational_folder_and_source_rule_rejected(self):
        self.advance({".gitignore": b"/frontend\n.stitch/\n"})
        self.blocked()
        self.update("cueva", self.base)
        self.source = self.base
        self.advance({".stitch/data.txt": b"must not be tracked\n"})
        self.blocked()

    def test_upstream_merge_from_master_is_incorporated(self):
        master = self.commit([self.base], {"master.txt": b"master change\n"})
        self.source = self.commit([self.source, master], {"master.txt": b"master change\n"})
        self.update("cueva", self.source)
        self.execute(apply=True)
        self.assertEqual(self.git("show", "lab/cueva:master.txt"), "master change")

    def test_source_rewrite_after_sync_rejected(self):
        self.advance({"feature.txt": b"v1\n"})
        self.execute(apply=True)
        self.update("cueva", self.base)
        self.blocked()

    def test_source_changed_before_publication_stops(self):
        self.advance({"feature.txt": b"first\n"})
        self.blocked(before_check=lambda: self.advance({"another.txt": b"second\n"}))

    def test_destination_changed_before_publication_stops(self):
        self.advance({"feature.txt": b"official\n"})
        concurrent = self.commit([self.destination], {"human.txt": b"human\n"})
        with self.assertRaises(SyncError):
            self.engine().run("cueva", apply=True,
                              before_check=lambda: self.update("lab/cueva", concurrent))
        self.assertEqual(self.head("lab/cueva"), concurrent)

    def test_pre_push_race_fast_forward_and_rewind_rejected(self):
        self.advance({"feature.txt": b"official\n"})
        for concurrent in [self.commit([self.destination], {"human.txt": b"human\n"}), self.base]:
            with self.subTest(concurrent=concurrent):
                self.update("lab/cueva", self.destination)
                with self.assertRaises(SyncError):
                    self.engine().run("cueva", apply=True,
                                      before_push=lambda: self.update("lab/cueva", concurrent))
                self.assertEqual(self.head("lab/cueva"), concurrent)

    def test_pre_push_destination_deletion_does_not_recreate(self):
        self.advance({"feature.txt": b"official\n"})
        with self.assertRaises(SyncError):
            self.engine().run("cueva", apply=True,
                              before_push=lambda: self.git("update-ref", "-d", "refs/heads/lab/cueva"))
        self.assertNotIn("refs/heads/lab/cueva", self.git("show-ref"))

    def test_push_accepted_but_error_reported_is_confirmed(self):
        self.advance({"feature.txt": b"official\n"})
        engine = self.engine()
        original = engine.git
        def uncertain(*args, **kwargs):
            result = original(*args, **kwargs)
            if "push" in args:
                result.returncode = 1
            return result
        engine.git = uncertain
        result = engine.run("cueva", apply=True)
        self.assertEqual(result["status"], "confirmed_after_error")
        self.assertEqual(self.head("lab/cueva"), result["commit"])

    def test_removed_official_ignore_restores_only_operational_rule(self):
        self.advance({".gitignore": None})
        self.execute(apply=True)
        self.assertEqual(self.git("show", "lab/cueva:.gitignore"), ".stitch/")

    def test_base_without_readme_or_ignore_merges_new_official_file(self):
        base = self.commit([], {"feature.txt": b"base\n"})
        destination = self.commit([base], {"README.md": LAB_README, ".gitignore": b".stitch/\n"})
        source = self.commit([base], {".gitignore": b"/build\n", "feature.txt": b"official\n"})
        self.update("cueva", source)
        self.update("lab/cueva", destination)
        self.execute(apply=True)
        self.assertEqual(self.git("show", "lab/cueva:.gitignore"), "/build\n.stitch/")
        self.assertEqual(self.git("show", "lab/cueva:README.md").encode() + b"\n", LAB_README)

    def test_no_newline_ignore_rules_survive(self):
        self.advance({".gitignore": b"/frontend\n/build"})
        self.execute(apply=True)
        self.assertEqual(self.git("show", "lab/cueva:.gitignore"), "/frontend\n/build\n.stitch/")

    def test_crlf_operational_readme_preserved_byte_for_byte(self):
        content = LAB_README.replace(b"\n", b"\r\n")
        self.destination = self.commit([self.destination], {"README.md": content})
        self.update("lab/cueva", self.destination)
        self.advance({"feature.txt": b"official\n"})
        result = self.execute(apply=True)
        engine = self.engine()
        engine.git("fetch", "origin", "lab/cueva")
        self.assertEqual(engine.blob(engine.entry(result["commit"], "README.md")), content)

    def test_arbitrary_remote_and_source_rejected(self):
        with self.assertRaises(SyncError):
            Synchronizer(self.root / "invalid", "https://example.invalid/other.git")
        with self.assertRaises(SyncError):
            self.engine().run("lab/cueva", apply=True)

    def test_token_not_persisted_to_config(self):
        engine = Synchronizer(self.root / "credential" / "objects.git", str(self.remote), token="fixture-secret")
        raw = (engine.directory / "config").read_text()
        self.assertNotIn("fixture-secret", raw)
        self.assertNotIn("AUTHORIZATION", raw)

    def test_hook_rejects_inverse_destination_and_multiple_updates(self):
        self.advance({"feature.txt": b"official\n"})
        result = self.execute()
        env = {"SYNC_EXPECT_COMMIT": result["commit"], "SYNC_EXPECT_DESTINATION": "lab/cueva",
               "SYNC_EXPECT_OLD": self.destination}
        valid = f"HEAD {result['commit']} refs/heads/lab/cueva {self.destination}"
        for lines in [[], [valid, valid], [valid.replace("refs/heads/lab/cueva", "refs/heads/cueva")],
                      [valid.replace(self.destination, "0" * 40)]]:
            with self.subTest(lines=lines), self.assertRaises(ValueError):
                validate(lines, env)


if __name__ == "__main__":
    unittest.main()
