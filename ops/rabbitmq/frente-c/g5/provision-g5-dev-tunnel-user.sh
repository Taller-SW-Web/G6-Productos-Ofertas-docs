#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

USER_NAME='g5_tunnel'
GROUP_NAME='g6-rabbitmq-tunnel'
POLICY='/etc/ssh/sshd_config.d/99-g6-rabbitmq-tunnel.conf'
POLICY_SOURCE="$(dirname -- "$0")/sshd-g6-rabbitmq-tunnel.conf.example"

[[ "$(id -u)" -eq 0 ]] || { echo 'Run as root.' >&2; exit 2; }
[[ "${1:-g5_tunnel}" == "$USER_NAME" ]] || { echo 'Only the fixed shared G5 SSH account g5_tunnel is allowed.' >&2; exit 2; }
[[ -r "$POLICY_SOURCE" && -r "$POLICY" ]] || { echo 'Shared restricted tunnel policy is not installed.' >&2; exit 2; }
if getent passwd "$USER_NAME" >/dev/null; then echo 'Refusing to change an existing account.' >&2; exit 3; fi

IFS= read -r PUBLIC_KEY || { echo 'Expected one public SSH key on stdin.' >&2; exit 2; }
PUBLIC_KEY="${PUBLIC_KEY%$'\r'}"
[[ -n "$PUBLIC_KEY" && "$PUBLIC_KEY" != *$'\n'* ]] || { echo 'Expected exactly one public SSH key line.' >&2; exit 2; }
KEY_TYPE="$(awk '{print $1}' <<<"$PUBLIC_KEY")"; KEY_DATA="$(awk '{print $2}' <<<"$PUBLIC_KEY")"
KEY_COMMENT="$(awk '{for (i=3; i<=NF; i++) printf "%s%s", (i==3?"":" "), $i}' <<<"$PUBLIC_KEY")"
[[ "$KEY_TYPE" == 'ssh-ed25519' && "$KEY_DATA" =~ ^[A-Za-z0-9+/]+={0,2}$ ]] || { echo 'Only an ssh-ed25519 public key is accepted.' >&2; exit 2; }

KEY_TMP="$(mktemp /run/g5-tunnel-key.XXXXXX)"; USER_CREATED=0
cleanup() { rc=$?; rm -f -- "$KEY_TMP"; if [[ "$USER_CREATED" -eq 1 && "$rc" -ne 0 ]]; then userdel --remove "$USER_NAME" >/dev/null 2>&1 || true; fi; return "$rc"; }
trap cleanup EXIT
printf '%s %s %s\n' "$KEY_TYPE" "$KEY_DATA" "$KEY_COMMENT" >"$KEY_TMP"
ssh-keygen -lf "$KEY_TMP" >/dev/null || { echo 'Public key validation failed.' >&2; exit 2; }
getent group "$GROUP_NAME" >/dev/null || { echo 'Expected shared restricted tunnel group is missing.' >&2; exit 4; }
useradd --create-home --home-dir "/home/$USER_NAME" --shell /usr/sbin/nologin --gid "$GROUP_NAME" "$USER_NAME"
USER_CREATED=1
passwd --lock "$USER_NAME" >/dev/null
install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0700 "/home/$USER_NAME/.ssh"
printf 'restrict,port-forwarding,permitopen="127.0.0.1:5672" %s %s %s\n' "$KEY_TYPE" "$KEY_DATA" "$KEY_COMMENT" >"/home/$USER_NAME/.ssh/authorized_keys"
chown "$USER_NAME:$GROUP_NAME" "/home/$USER_NAME/.ssh/authorized_keys"; chmod 0600 "/home/$USER_NAME/.ssh/authorized_keys"
EFFECTIVE="$(sshd -T -C "user=$USER_NAME,host=localhost,addr=127.0.0.1")"
for expected in 'authenticationmethods publickey' 'passwordauthentication no' 'allowtcpforwarding local' 'allowstreamlocalforwarding no' 'permitopen 127.0.0.1:5672' 'allowagentforwarding no' 'x11forwarding no' 'permittunnel no' 'permittty no' 'maxsessions 0' 'forcecommand /usr/sbin/nologin'; do
  grep -Fqx "$expected" <<<"$EFFECTIVE" || { echo "Effective SSH policy missing: $expected" >&2; exit 5; }
done
for forbidden_group in sudo docker lxd; do id -nG "$USER_NAME" | tr ' ' '\n' | grep -Fxq "$forbidden_group" && { echo "Unexpected privileged group: $forbidden_group" >&2; exit 5; } || true; done
sshd -t
USER_CREATED=0
trap - EXIT
printf 'Provisioned restricted G5 SSH tunnel account %s. Public key fingerprint: ' "$USER_NAME"
ssh-keygen -lf "$KEY_TMP" | awk '{print $2}'
printf 'Local forwarding only to 127.0.0.1:5672; no shell, sudo, Docker, agent, X11, reverse, Unix-socket or tunnel forwarding.\n'
rm -f -- "$KEY_TMP"
