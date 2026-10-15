#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

USER_NAME="${1:?usage: sudo bash provision-dev-tunnel-user.sh g6_<login> < public-key-on-stdin}"
GROUP_NAME='g6-rabbitmq-tunnel'
POLICY='/etc/ssh/sshd_config.d/99-g6-rabbitmq-tunnel.conf'
POLICY_SOURCE="$(dirname -- "$0")/sshd-g6-rabbitmq-tunnel.conf.example"

[[ "$(id -u)" -eq 0 ]] || { echo 'Run as root.' >&2; exit 2; }
[[ "$USER_NAME" =~ ^g6_[a-z0-9][a-z0-9_-]{1,30}$ ]] || { echo 'Invalid tunnel account name.' >&2; exit 2; }
[[ -r "$POLICY_SOURCE" ]] || { echo 'Missing SSH policy template.' >&2; exit 2; }
if getent passwd "$USER_NAME" >/dev/null; then
  echo 'Refusing to change an existing account.' >&2
  exit 3
fi

IFS= read -r PUBLIC_KEY || { echo 'Expected one public SSH key on stdin.' >&2; exit 2; }
PUBLIC_KEY="${PUBLIC_KEY%$'\r'}"
[[ -n "$PUBLIC_KEY" && "$PUBLIC_KEY" != *$'\n'* ]] || { echo 'Expected exactly one public SSH key line.' >&2; exit 2; }
KEY_TYPE="$(awk '{print $1}' <<<"$PUBLIC_KEY")"
KEY_DATA="$(awk '{print $2}' <<<"$PUBLIC_KEY")"
KEY_COMMENT="$(awk '{for (i=3; i<=NF; i++) printf "%s%s", (i==3?"":" "), $i}' <<<"$PUBLIC_KEY")"
[[ "$KEY_TYPE" == 'ssh-ed25519' && "$KEY_DATA" =~ ^[A-Za-z0-9+/]+={0,2}$ ]] || {
  echo 'Only a valid ssh-ed25519 public key is accepted.' >&2; exit 2;
}

KEY_TMP="$(mktemp /run/g6-tunnel-key.XXXXXX)"
POLICY_TMP="$(mktemp /run/g6-tunnel-sshd-policy.XXXXXX)"
BACKUP_TMP=''
USER_CREATED=0
POLICY_INSTALLED=0
RELOAD_ATTEMPTED=0
COMMITTED=0
cleanup() {
  rc=$?
  if [[ "$COMMITTED" -ne 1 ]]; then
    if [[ "$POLICY_INSTALLED" -eq 1 ]]; then
      if [[ -n "$BACKUP_TMP" ]]; then install -o root -g root -m 0644 "$BACKUP_TMP" "$POLICY"; else rm -f -- "$POLICY"; fi
      if [[ "$RELOAD_ATTEMPTED" -eq 1 ]]; then systemctl reload ssh >/dev/null 2>&1 || true; fi
    fi
    if [[ "$USER_CREATED" -eq 1 ]]; then userdel --remove "$USER_NAME" >/dev/null 2>&1 || true; fi
  fi
  rm -f -- "$KEY_TMP" "$POLICY_TMP"
  if [[ -n "$BACKUP_TMP" ]]; then rm -f -- "$BACKUP_TMP"; fi
  return "$rc"
}
trap cleanup EXIT
printf '%s %s %s\n' "$KEY_TYPE" "$KEY_DATA" "$KEY_COMMENT" >"$KEY_TMP"
ssh-keygen -lf "$KEY_TMP" >/dev/null || { echo 'Public key validation failed.' >&2; exit 2; }

if ! getent group "$GROUP_NAME" >/dev/null; then groupadd --system "$GROUP_NAME"; fi
useradd --create-home --home-dir "/home/$USER_NAME" --shell /usr/sbin/nologin --gid "$GROUP_NAME" "$USER_NAME"
USER_CREATED=1
# Keep PAM account state usable while SSH password authentication remains disabled.
RANDOM_PASSWORD="$(openssl rand -base64 48 | tr -d '\n')"
PASSWORD_HASH="$(printf '%s\n' "$RANDOM_PASSWORD" | openssl passwd -6 -stdin)"
unset RANDOM_PASSWORD
printf '%s:%s\n' "$USER_NAME" "$PASSWORD_HASH" | chpasswd --encrypted
unset PASSWORD_HASH

install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0700 "/home/$USER_NAME/.ssh"
printf 'restrict,port-forwarding,permitopen="127.0.0.1:5672" %s %s %s\n' \
  "$KEY_TYPE" "$KEY_DATA" "$KEY_COMMENT" >"/home/$USER_NAME/.ssh/authorized_keys"
chown "$USER_NAME:$GROUP_NAME" "/home/$USER_NAME/.ssh/authorized_keys"
chmod 0600 "/home/$USER_NAME/.ssh/authorized_keys"

if [[ -e "$POLICY" ]]; then
  BACKUP_TMP="$(mktemp /run/g6-tunnel-sshd-policy-backup.XXXXXX)"
  cp -p -- "$POLICY" "$BACKUP_TMP"
fi
install -o root -g root -m 0644 "$POLICY_SOURCE" "$POLICY_TMP"
install -o root -g root -m 0644 "$POLICY_TMP" "$POLICY"
POLICY_INSTALLED=1

if ! sshd -t; then
  echo 'sshd config validation failed; restored prior policy and removed the new account.' >&2
  exit 4
fi

EFFECTIVE="$(sshd -T -C "user=$USER_NAME,host=localhost,addr=127.0.0.1")"
for expected in \
  'authenticationmethods publickey' \
  'passwordauthentication no' \
  'allowtcpforwarding local' \
  'allowstreamlocalforwarding no' \
  'permitopen 127.0.0.1:5672' \
  'allowagentforwarding no' \
  'x11forwarding no' \
  'permittunnel no' \
  'permittty no' \
  'maxsessions 0' \
  'forcecommand /usr/sbin/nologin'; do
  grep -Fqx "$expected" <<<"$EFFECTIVE" || {
    echo "Effective sshd policy did not include: $expected" >&2
    exit 5
  }
done

for forbidden_group in sudo docker lxd; do
  if id -nG "$USER_NAME" | tr ' ' '\n' | grep -Fxq "$forbidden_group"; then
    echo "New user unexpectedly belongs to $forbidden_group." >&2
    exit 5
  fi
done

RELOAD_ATTEMPTED=1
if ! systemctl reload ssh; then
  echo 'sshd reload failed; restored prior policy and removed the new account.' >&2
  exit 6
fi
COMMITTED=1

printf 'Provisioned restricted SSH tunnel account %s. Public key fingerprint: ' "$USER_NAME"
ssh-keygen -lf "$KEY_TMP" | awk '{print $2}'
printf 'Groups: '
id -nG "$USER_NAME"
printf 'Effective forwarding policy validated; administrative account and existing sessions were not changed.\n'
