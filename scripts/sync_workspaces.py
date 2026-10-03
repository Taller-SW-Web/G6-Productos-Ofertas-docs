"""Official -> lab synchronization using isolated Git objects, without a checkout."""
import argparse
import base64
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

OWNERS = ("castilla", "poma", "cueva", "lopez", "taco", "vera")
REPOSITORY = "Taller-SW-Web/Productos-y-Ofertas-docs"
REMOTE = "https://github.com/" + REPOSITORY + ".git"
CONFIG_KEYS = {"schema_version", "repository", "enabled_sources", "pairs",
               "operational_readme", "local_ignore_line"}


class SyncError(RuntimeError):
    pass


def load_config(path):
    def unique_keys(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise SyncError("La configuración contiene una clave repetida.")
            result[key] = value
        return result
    config = json.loads(Path(path).read_text(encoding="utf-8"), object_pairs_hook=unique_keys)
    expected = [{"source": owner, "destination": "lab/" + owner} for owner in OWNERS]
    if (not isinstance(config, dict) or set(config) != CONFIG_KEYS or type(config["schema_version"]) is not int or
            config["schema_version"] != 1 or config["repository"] != REPOSITORY or
            config["pairs"] != expected or config["operational_readme"] != "README.md" or
            config["local_ignore_line"] != ".stitch/"):
        raise SyncError("Configuración fuera del contrato autorizado.")
    enabled = config["enabled_sources"]
    if (not isinstance(enabled, list) or not enabled or
            any(not isinstance(item, str) or item not in OWNERS for item in enabled) or
            len(set(enabled)) != len(enabled)):
        raise SyncError("Los orígenes habilitados deben ser únicos y oficiales.")
    return config


def select_pairs(config, event, ref="", selection=""):
    enabled = config["enabled_sources"]
    if event == "push":
        selected = [ref] if ref in enabled else []
    elif event == "workflow_dispatch":
        if selection == "todos":
            selected = enabled
        elif selection in enabled:
            selected = [selection]
        else:
            raise SyncError("El par solicitado no está habilitado.")
    elif event in ("schedule", "workflow_run"):
        selected = enabled
    else:
        raise SyncError("Evento no autorizado.")
    return [pair for pair in config["pairs"] if pair["source"] in selected]


class Synchronizer:
    def __init__(self, directory, remote=REMOTE, token=None):
        self.directory = Path(directory)
        # Only the fixed project or a local bare fixture can be used.
        if remote != REMOTE:
            local = Path(remote)
            if not local.is_absolute() or not (local / "HEAD").is_file() or not (local / "objects").is_dir():
                raise SyncError("Remoto fuera del repositorio autorizado.")
        self.remote = remote
        self.directory.mkdir(parents=True, exist_ok=True)
        self.env = os.environ.copy()
        # Do not inherit credentials, hooks or alternate object stores from a checkout.
        for key in list(self.env):
            if key.startswith("GIT_") or key.startswith("SYNC_GITHUB_TOKEN"):
                self.env.pop(key)
        self.env.update({"GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull,
                         "GIT_TERMINAL_PROMPT": "0"})
        if token:
            credential = base64.b64encode(("x-access-token:" + token).encode()).decode()
            self.env.update({"GIT_CONFIG_COUNT": "1",
                             "GIT_CONFIG_KEY_0": "http.https://github.com/.extraheader",
                             "GIT_CONFIG_VALUE_0": "AUTHORIZATION: basic " + credential})
        self.git("init", "--bare", str(self.directory))
        self.git("remote", "add", "origin", remote)
        self.git("config", "user.name", "github-actions[bot]")
        self.git("config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com")

    def git(self, *args, data=None, extra_env=None, allowed=(0,)):
        env = self.env.copy()
        env.update(extra_env or {})
        result = subprocess.run(["git", "-C", str(self.directory), *args],
                                input=data, capture_output=True, env=env)
        if result.returncode not in allowed:
            # Git errors can include remote addresses; never emit credentials/config.
            raise SyncError("Falló Git durante " + args[0] + "; no se autoriza continuar.")
        return result

    def text(self, *args):
        return self.git(*args).stdout.decode().strip()

    def ancestor(self, first, second):
        return self.git("merge-base", "--is-ancestor", first, second,
                        allowed=(0, 1)).returncode == 0

    def remote_heads(self, source, destination):
        result = self.text("ls-remote", "--heads", "origin",
                           "refs/heads/" + source, "refs/heads/" + destination)
        refs = dict(line.split("\t")[::-1] for line in result.splitlines())
        try:
            return refs["refs/heads/" + source], refs["refs/heads/" + destination]
        except KeyError:
            raise SyncError("Falta el origen o el destino; no se crean ramas.") from None

    def entry(self, tree, path):
        raw = self.git("ls-tree", "-z", tree, "--", path).stdout
        if not raw:
            return None
        header, _ = raw.rstrip(b"\0").split(b"\t", 1)
        mode, kind, oid = header.decode().split()
        if kind != "blob" or mode not in ("100644", "100755"):
            raise SyncError("La excepción operativa debe ser un archivo regular: " + path)
        return mode, oid

    def blob(self, entry):
        return self.git("cat-file", "blob", entry[1]).stdout if entry else b""

    def hash_blob(self, data):
        return self.git("hash-object", "-w", "--stdin", data=data).stdout.decode().strip()

    def edit_tree(self, tree, entries):
        # The index is disposable and separate from the developer's checkout.
        index = str(self.directory.parent / "index")
        Path(index).unlink(missing_ok=True)
        env = {"GIT_INDEX_FILE": index}
        self.git("read-tree", tree, extra_env=env)
        for path, entry in entries.items():
            if entry:
                self.git("update-index", "--add", "--cacheinfo",
                         entry[0] + "," + entry[1] + "," + path, extra_env=env)
            else:
                deletion = ("0 " + "0" * 40 + "\t" + path + "\n").encode()
                self.git("update-index", "--index-info", data=deletion, extra_env=env)
        return self.git("write-tree", extra_env=env).stdout.decode().strip()

    def normalize(self, tree, base_readme, base_ignore):
        entry = self.entry(tree, ".gitignore")
        raw = self.blob(entry)
        clean = b"".join(line for line in raw.splitlines(keepends=True)
                         if line.rstrip(b"\r\n") != b".stitch/")
        ignore = (entry[0], self.hash_blob(clean)) if entry else None
        if entry and not clean and not base_ignore:
            ignore = None
        return self.edit_tree(tree, {"README.md": base_readme, ".gitignore": ignore})

    def validate_trees(self, source, destination, owner):
        readme = self.entry(destination, "README.md")
        content = self.blob(readme).decode("utf-8", errors="strict")
        if (not content.splitlines() or content.splitlines()[0] != "# LAB — " + owner or
                "Rama temporal: `lab/" + owner + "`" not in content or
                "Rama oficial: `" + owner + "`" not in content):
            raise SyncError("README de destino no corresponde al laboratorio autorizado.")
        if b".stitch/" in self.blob(self.entry(source, ".gitignore")).splitlines():
            raise SyncError("El origen contiene una exclusión exclusiva del laboratorio.")
        for tree in (source, destination):
            paths = self.git("ls-tree", "-r", "--name-only", "-z", tree).stdout.split(b"\0")
            if any(path == b".stitch" or path.startswith(b".stitch/") for path in paths):
                raise SyncError("La carpeta operativa excluida no debe estar versionada.")
        return readme

    def check_source_history(self, source, destination, owner):
        log = self.git("log", "--format=%H%x00%B%x00", destination,
                       "--grep=Source-Branch: " + owner).stdout.decode()
        parts = log.split("\0")
        for i in range(0, len(parts) - 1, 2):
            commit, body = parts[i].strip(), parts[i + 1]
            match = re.search(r"^Source-Revision: ([0-9a-f]{40})$", body, re.MULTILINE)
            if not match or "Source-Branch: " + owner not in body:
                continue
            parents = self.text("rev-list", "--parents", "-n", "1", commit).split()[1:]
            if len(parents) == 2 and parents[1] == match[1]:
                if not self.ancestor(match[1], source):
                    raise SyncError("El origen fue reescrito; se requiere revisión manual.")
                break

    def run(self, source, apply=False, before_check=None, before_push=None):
        if source not in OWNERS:
            raise SyncError("Origen fuera de la lista autorizada.")
        destination = "lab/" + source
        old_source, old_destination = self.remote_heads(source, destination)
        self.git("fetch", "--no-tags", "origin",
                 "+refs/heads/" + source + ":refs/source",
                 "+refs/heads/" + destination + ":refs/destination")
        if (self.text("rev-parse", "refs/source"), self.text("rev-parse", "refs/destination")) != (old_source, old_destination):
            raise SyncError("Las ramas cambiaron durante la lectura; repetir con datos actuales.")
        self.check_source_history(old_source, old_destination, source)
        readme = self.validate_trees(old_source, old_destination, source)
        result = {"source": source, "destination": destination,
                  "source_sha": old_source, "destination_sha": old_destination}
        if self.ancestor(old_source, old_destination):
            return dict(result, status="up_to_date")
        bases = self.git("merge-base", "--all", old_source, old_destination,
                         allowed=(0, 1)).stdout.decode().split()
        if len(bases) != 1:
            raise SyncError("La historia debe tener una única base común; requiere revisión manual.")
        base = bases[0]
        base_readme = self.entry(base, "README.md")
        base_ignore = self.entry(base, ".gitignore")
        trees = [self.normalize(tree, base_readme, base_ignore)
                 for tree in (base, old_destination, old_source)]
        merged = self.git("merge-tree", "--write-tree", "--name-only", "-z", "--no-messages",
                          "--merge-base=" + trees[0], trees[1], trees[2], allowed=(0, 1))
        pieces = merged.stdout.split(b"\0")
        if merged.returncode:
            paths = [part.decode("utf-8", errors="replace") for part in pieces[1:] if part]
            raise SyncError("Conflicto funcional: " + json.dumps(paths, ensure_ascii=False) +
                            "; origen=" + old_source + "; destino=" + old_destination)
        tree = pieces[0].decode()
        ignore_entry = self.entry(tree, ".gitignore")
        ignore = self.blob(ignore_entry)
        if ignore and not ignore.endswith(b"\n"):
            ignore += b"\n"
        ignore += b".stitch/\n"
        tree = self.edit_tree(tree, {"README.md": readme,
                                   ".gitignore": (ignore_entry[0] if ignore_entry else "100644",
                                                  self.hash_blob(ignore))})
        if self.entry(tree, "README.md") != readme:
            raise SyncError("No se preservó exactamente el README operativo.")
        message = ("Sincronizar " + source + " con su rama de trabajo\n\n" +
                   "Source-Branch: " + source + "\nSource-Revision: " + old_source + "\n")
        commit = self.git("commit-tree", tree, "-p", old_destination, "-p", old_source,
                          data=message.encode()).stdout.decode().strip()
        if not self.ancestor(old_destination, commit) or not self.ancestor(old_source, commit):
            raise SyncError("El resultado no conserva ambas historias.")
        result.update(commit=commit, tree=tree)
        if not apply:
            return dict(result, status="dry_run")
        if before_check:
            before_check()
        if self.remote_heads(source, destination) != (old_source, old_destination):
            raise SyncError("Cambio concurrente; no se publica un resultado obsoleto.")
        hooks = self.directory.parent / "hooks"
        hooks.mkdir()
        hook = hooks / "pre-push"
        hook.write_text('#!/bin/sh\nexec "$SYNC_PYTHON" "$SYNC_HOOK_SCRIPT" "$@"\n', encoding="utf-8", newline="\n")
        hook.chmod(0o755)
        env = {"SYNC_PYTHON": Path(sys.executable).as_posix(),
               "SYNC_HOOK_SCRIPT": Path(__file__).with_name("sync_pre_push.py").resolve().as_posix(),
               "SYNC_EXPECT_REMOTE": self.remote,
               "SYNC_EXPECT_OLD": old_destination,
               "SYNC_EXPECT_COMMIT": commit,
               "SYNC_EXPECT_DESTINATION": destination}
        if before_push:
            before_push()
        push = self.git("-c", "core.hooksPath=" + hooks.as_posix(), "push", "--porcelain", "origin",
                        commit + ":refs/heads/" + destination, extra_env=env, allowed=tuple(range(256)))
        # Read back even after an error: the server might have accepted the update.
        _, actual_destination = self.remote_heads(source, destination)
        if actual_destination == commit:
            return dict(result, status="published" if not push.returncode else "confirmed_after_error")
        raise SyncError("Publicación no confirmada; no se fuerza ni se reintenta automáticamente.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("plan", "run"))
    parser.add_argument("--config", required=True)
    parser.add_argument("--source")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    try:
        config = load_config(args.config)
        if args.command == "plan":
            pairs = select_pairs(config, os.environ.get("SYNC_EVENT", ""),
                                 os.environ.get("SYNC_REF", ""), os.environ.get("SYNC_SELECTION", ""))
            output = "matrix=" + json.dumps({"include": pairs}, separators=(",", ":")) + "\n"
            output += "has_work=" + str(bool(pairs)).lower() + "\n"
            if os.environ.get("GITHUB_OUTPUT"):
                with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as file:
                    file.write(output)
            print(output, end="")
            return 0
        if args.source not in config["enabled_sources"]:
            raise SyncError("El origen solicitado no está habilitado.")
        if args.apply and (os.environ.get("GITHUB_ACTIONS") != "true" or
                           os.environ.get("GITHUB_REPOSITORY") != REPOSITORY or
                           not os.environ.get("SYNC_GITHUB_TOKEN")):
            raise SyncError("La publicación al proyecto se permite únicamente desde su GitHub Actions.")
        with tempfile.TemporaryDirectory(prefix="sync-workspace-") as directory:
            sync = Synchronizer(Path(directory) / "objects.git", token=os.environ.get("SYNC_GITHUB_TOKEN"))
            result = sync.run(args.source, apply=args.apply)
        print(json.dumps(result, ensure_ascii=False))
        summary = os.environ.get("GITHUB_STEP_SUMMARY")
        if summary:
            with open(summary, "a", encoding="utf-8") as file:
                file.write("### Sincronización\n\n```json\n" + json.dumps(result, indent=2) + "\n```\n")
        return 0
    except (SyncError, ValueError, OSError) as error:
        print("Sincronización detenida: " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
