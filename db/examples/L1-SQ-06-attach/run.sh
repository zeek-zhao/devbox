#!/usr/bin/env bash
# L1-SQ-06-attach · 附加数据库
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

DB=/tmp/l1-sq-06-attach.db
ARCHIVE=/tmp/l1-sq-06-attach-archive.db
SQL="$(mktemp)"
trap 'tb rm -f "$DB" "$ARCHIVE"; rm -f "$SQL"' EXIT
tb rm -f "$DB" "$ARCHIVE"
cat >"$SQL" <<'SQL'
.mode tabs
.headers off
CREATE TABLE main.customers (customer_key TEXT PRIMARY KEY, customer_name TEXT NOT NULL);
INSERT INTO main.customers VALUES ('c-1','Ari'), ('c-2','Bea');
ATTACH DATABASE '/tmp/l1-sq-06-attach-archive.db' AS archive;
CREATE TABLE archive.orders (order_key TEXT PRIMARY KEY, customer_key TEXT NOT NULL);
INSERT INTO archive.orders VALUES ('o-1','c-1'), ('o-2','c-2'), ('o-3','c-1');
SELECT c.customer_key, c.customer_name, COUNT(o.order_key)
FROM main.customers AS c
JOIN archive.orders AS o ON o.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_name
ORDER BY c.customer_key;
DETACH DATABASE archive;
SQL
tb sqlite3 "$DB" <"$SQL"
