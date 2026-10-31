#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_pg_02_crud
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

sql_file="$(mktemp)"
trap 'rm -f "$sql_file"' EXIT
cat >"$sql_file" <<SQL
\set QUIET 1
\connect $NS
CREATE TABLE stock (
    sku text PRIMARY KEY,
    qty integer NOT NULL
);
CREATE TABLE adjustments (
    sku text PRIMARY KEY,
    amount integer NOT NULL
);
INSERT INTO stock VALUES ('apple', 3), ('pear', 5);
INSERT INTO adjustments VALUES ('pear', 2);
INSERT INTO stock VALUES ('apple', 4)
ON CONFLICT (sku) DO UPDATE SET qty = EXCLUDED.qty
RETURNING sku || ':' || qty;
UPDATE stock AS s
SET qty = s.qty + a.amount
FROM adjustments AS a
WHERE s.sku = a.sku
RETURNING s.sku || ':' || s.qty;
DELETE FROM stock AS s
USING adjustments AS a
WHERE s.sku = a.sku
RETURNING s.sku;
SELECT sku || ':' || qty FROM stock ORDER BY sku;
SQL
psql_file "$sql_file"
