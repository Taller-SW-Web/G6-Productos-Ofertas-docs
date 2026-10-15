#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
trap 'rc=$?; echo "Provisioner failed on line ${LINENO} (status ${rc}); rolling back if needed." >&2' ERR
CONTAINER="${RABBITMQ_CONTAINER_NAME:-g6-po-rabbitmq-1}"
VHOST='g6-productos-ofertas'; USER='g5_ventas'
[[ "$(id -u)" -eq 0 ]] || { echo 'Run as root.' >&2; exit 2; }
IFS= read -r PASSWORD || { echo 'Expected one password on stdin.' >&2; exit 2; }
PASSWORD="${PASSWORD%$'\r'}"
[[ "$PASSWORD" =~ ^[A-Za-z0-9_-]{43}$ ]] || { echo 'Malformed URL-safe credential.' >&2; exit 2; }
docker=(sudo -n docker)
"${docker[@]}" exec "$CONTAINER" rabbitmq-diagnostics -q check_running >/dev/null
"${docker[@]}" exec "$CONTAINER" rabbitmqctl list_vhosts --no-table-headers name | awk -v expected="$VHOST" '$0 == expected { found=1 } END { exit !found }'
CURRENT="$("${docker[@]}" exec "$CONTAINER" rabbitmqctl list_users --no-table-headers)"
if awk -F '\t' -v expected="$USER" '$1 == expected { found=1 } END { exit !found }' <<<"$CURRENT"; then
  echo 'Refusing to replace existing g5_ventas identity or ACL.' >&2; exit 20
fi
printf '%s\n' "$PASSWORD" | "${docker[@]}" exec -i "$CONTAINER" rabbitmqctl add_user "$USER" >/dev/null
unset PASSWORD
USER_CREATED=1
cleanup_user() { rc=$?; if [[ "${USER_CREATED:-0}" -eq 1 && "$rc" -ne 0 ]]; then "${docker[@]}" exec "$CONTAINER" rabbitmqctl delete_user "$USER" >/dev/null 2>&1 || true; fi; return "$rc"; }
trap cleanup_user EXIT
"${docker[@]}" exec "$CONTAINER" rabbitmqctl set_permissions -p "$VHOST" "$USER" '^$' '^po\.comandos\.x$' '^po\.ventas\.q$' >/dev/null
"${docker[@]}" exec "$CONTAINER" rabbitmqctl set_topic_permissions -p "$VHOST" "$USER" po.comandos.x '^(?:promotions\.coupon\.consumption\.requested|promotions\.coupon\.restoration\.requested)$' '^$' >/dev/null
"${docker[@]}" exec "$CONTAINER" rabbitmqctl list_users --no-table-headers | awk -F '\t' -v u="$USER" '$1==u && ($2=="" || $2=="[]") {ok=1} END{exit !ok}' || { echo 'Unexpected RabbitMQ user tags; expected no administrative tags.' >&2; exit 23; }
"${docker[@]}" exec "$CONTAINER" rabbitmqctl list_permissions -p "$VHOST" --no-table-headers | awk -F '\t' -v u="$USER" '$1==u && $2=="^$" && $3=="^po\\.comandos\\.x$" && $4=="^po\\.ventas\\.q$" {ok=1} END{exit !ok}' || { echo 'Resource ACL verification failed.' >&2; exit 21; }
"${docker[@]}" exec "$CONTAINER" rabbitmqctl list_topic_permissions -p "$VHOST" --no-table-headers | awk -F '\t' -v u="$USER" '$1==u && $2=="po.comandos.x" && $3=="^(?:promotions\\.coupon\\.consumption\\.requested|promotions\\.coupon\\.restoration\\.requested)$" && $4=="^$" {ok=1} END{exit !ok}' || { echo 'Topic ACL verification failed.' >&2; exit 22; }
USER_CREATED=0
trap - EXIT
echo 'Created g5_ventas with exact rc.3 candidate ACL; no tags or retry/DLX permissions were granted.'
