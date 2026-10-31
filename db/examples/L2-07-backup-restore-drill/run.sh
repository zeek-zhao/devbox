#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

SOURCE=db_l2_07_backup_restore_drill
RESTORE=db_l2_07_backup_restore_drill_restore
DUMP="/tmp/${SOURCE}.dump"
psql_db "DROP DATABASE IF EXISTS $RESTORE" >/dev/null
psql_db "DROP DATABASE IF EXISTS $SOURCE" >/dev/null
psql_db "CREATE DATABASE $SOURCE" >/dev/null
psql_db "CREATE DATABASE $RESTORE" >/dev/null

sql_file="$(mktemp)"
trap 'rm -f "$sql_file"; tb rm -f "$DUMP" >/dev/null' EXIT
cat >"$sql_file" <<SQL
\set QUIET 1
\connect $SOURCE
CREATE TABLE orders (
    order_key text PRIMARY KEY,
    amount integer NOT NULL
);
INSERT INTO orders VALUES ('A-100', 12), ('A-200', 25), ('A-300', 7);
SQL
psql_file "$sql_file"

tb pg_dump -h postgres -U devbox --no-owner --format=custom \
  -d "$SOURCE" -f "$DUMP" >/dev/null
tb pg_restore -h postgres -U devbox --no-owner --exit-on-error \
  -d "$RESTORE" "$DUMP" >/dev/null

query="SELECT count(*) || ':' || md5(string_agg(order_key || ':' || amount, ',' ORDER BY order_key)) FROM orders"
source_check="$(tb psql -h postgres -U devbox -d "$SOURCE" -t -A -q -c "$query")"
restore_check="$(tb psql -h postgres -U devbox -d "$RESTORE" -t -A -q -c "$query")"
source_count="${source_check%%:*}"
restore_count="${restore_check%%:*}"
source_hash="${source_check#*:}"
restore_hash="${restore_check#*:}"
printf 'source rows=%s\n' "$source_count"
printf 'restored rows=%s\n' "$restore_count"
if [ "$source_count" != "$restore_count" ] || [ "$source_hash" != "$restore_hash" ]; then
  die "backup restore checksum mismatch"
fi
printf 'checksum match=true\n'
