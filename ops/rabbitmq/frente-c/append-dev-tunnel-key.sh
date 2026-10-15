#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
USER_NAME="${1:?usage: sudo bash append-dev-tunnel-key.sh g6_castilla < public-key-on-stdin}"
[[ "$(id -u)" -eq 0 ]] || { echo 'Run as root.' >&2; exit 2; }
[[ "$USER_NAME" == 'g6_castilla' ]] || { echo 'Only the pre-existing pilot account may receive an appended key.' >&2; exit 2; }
[[ "$(getent passwd "$USER_NAME" | cut -d: -f7)" == '/usr/sbin/nologin' ]] || { echo 'Unexpected shell on the existing account.' >&2; exit 3; }
id -nG "$USER_NAME" | tr ' ' '\n' | grep -Fxq 'g6-rabbitmq-tunnel' || { echo 'Existing account is not in the approved tunnel group.' >&2; exit 3; }
for forbidden in sudo docker lxd; do
  if id -nG "$USER_NAME" | tr ' ' '\n' | grep -Fxq "$forbidden"; then echo "Forbidden group: $forbidden" >&2; exit 3; fi
done
KEY_FILE="/home/$USER_NAME/.ssh/authorized_keys"
[[ -f "$KEY_FILE" && "$(stat -c '%U:%G:%a' "$KEY_FILE")" == "$USER_NAME:g6-rabbitmq-tunnel:600" ]] || { echo 'Existing authorized_keys ownership or mode is unexpected.' >&2; exit 3; }
IFS= read -r PUBLIC_KEY || { echo 'Expected one public SSH key on stdin.' >&2; exit 2; }
PUBLIC_KEY="${PUBLIC_KEY%$'\r'}"
[[ -n "$PUBLIC_KEY" && "$PUBLIC_KEY" != *$'\n'* ]] || { echo 'Expected exactly one public key line.' >&2; exit 2; }
KEY_TYPE="$(awk '{print $1}' <<<"$PUBLIC_KEY")"
KEY_DATA="$(awk '{print $2}' <<<"$PUBLIC_KEY")"
KEY_COMMENT="$(awk '{for (i=3; i<=NF; i++) printf "%s%s", (i==3?"":" "), $i}' <<<"$PUBLIC_KEY")"
[[ "$KEY_TYPE" == 'ssh-ed25519' && "$KEY_DATA" =~ ^[A-Za-z0-9+/]+={0,2}$ ]] || { echo 'Only a valid ssh-ed25519 public key is accepted.' >&2; exit 2; }
TMP_KEY="$(mktemp /run/g6-tunnel-key.XXXXXX)"
TMP_AUTH="$(mktemp "/home/$USER_NAME/.ssh/authorized_keys.XXXXXX")"
cleanup() { rm -f -- "$TMP_KEY" "$TMP_AUTH"; }
trap cleanup EXIT
printf '%s %s %s\n' "$KEY_TYPE" "$KEY_DATA" "$KEY_COMMENT" >"$TMP_KEY"
ssh-keygen -lf "$TMP_KEY" >/dev/null
if awk -v key="$KEY_DATA" '$2==key {found=1} END {exit !found}' "$KEY_FILE"; then echo 'This public key is already registered; no change made.'; exit 0; fi
cp -p -- "$KEY_FILE" "$TMP_AUTH"
printf 'restrict,port-forwarding,permitopen="127.0.0.1:5672" %s %s %s\n' "$KEY_TYPE" "$KEY_DATA" "$KEY_COMMENT" >>"$TMP_AUTH"
chown "$USER_NAME:g6-rabbitmq-tunnel" "$TMP_AUTH"
chmod 0600 "$TMP_AUTH"
sshd -t
mv -f -- "$TMP_AUTH" "$KEY_FILE"
trap - EXIT
rm -f -- "$TMP_KEY"
printf 'Appended key to %s without replacing existing entries. Fingerprint: ' "$USER_NAME"
ssh-keygen -lf <(printf '%s %s %s\n' "$KEY_TYPE" "$KEY_DATA" "$KEY_COMMENT") | awk '{print $2}'
printf 'authorized_keys entries: '
wc -l <"$KEY_FILE"
