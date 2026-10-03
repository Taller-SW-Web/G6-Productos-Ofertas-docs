"""Trusted pre-push check: a single, non-forced update of the observed lab ref."""
import os
import subprocess
import sys


def validate(lines, env):
    if len(lines) != 1:
        raise ValueError("La publicación debe actualizar exactamente un destino.")
    fields = lines[0].split()
    if len(fields) != 4:
        raise ValueError("Actualización remota no reconocida.")
    _, local_oid, remote_ref, remote_oid = fields
    if (local_oid != env["SYNC_EXPECT_COMMIT"] or
            remote_ref != "refs/heads/" + env["SYNC_EXPECT_DESTINATION"] or
            remote_oid != env["SYNC_EXPECT_OLD"] or
            set(remote_oid) == {"0"}):
        raise ValueError("El destino cambió o la actualización no está autorizada.")
    result = subprocess.run(
        ["git", "merge-base", "--is-ancestor", remote_oid, local_oid],
        capture_output=True)
    if result.returncode != 0:
        raise ValueError("La publicación debe conservar toda la historia del destino.")


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3 or sys.argv[1] != "origin" or sys.argv[2] != os.environ["SYNC_EXPECT_REMOTE"]:
            raise ValueError("Remoto no autorizado.")
        validate(sys.stdin.read().splitlines(), os.environ)
    except (ValueError, KeyError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
