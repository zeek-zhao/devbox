#!/usr/bin/env bash
# L1-SQ-02-crud · CRUD 与 UPSERT
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

DB=/tmp/l1-sq-02-crud.db
SQL="$(mktemp)"
trap 'tb rm -f "$DB"; rm -f "$SQL"' EXIT
tb rm -f "$DB"
cat >"$SQL" <<'SQL'
.mode tabs
.headers off
CREATE TABLE stock (item_key TEXT PRIMARY KEY, units INTEGER NOT NULL);
INSERT INTO stock VALUES ('tea', 3), ('coffee', 5);
SELECT 'before', COUNT(*) FROM stock;
INSERT INTO stock VALUES ('tea', 8)
ON CONFLICT(item_key) DO UPDATE SET units = excluded.units;
SELECT 'after-upsert', COUNT(*) FROM stock;
INSERT OR IGNORE INTO stock VALUES ('tea', 99);
INSERT OR REPLACE INTO stock VALUES ('juice', 4);
CREATE TABLE replenishment (item_key TEXT PRIMARY KEY, extra_units INTEGER NOT NULL);
INSERT INTO replenishment VALUES ('coffee', 2);
UPDATE stock SET units = units + replenishment.extra_units
FROM replenishment WHERE stock.item_key = replenishment.item_key;
UPDATE stock SET units = units - 1 WHERE item_key = 'tea'
RETURNING item_key, units;
SELECT item_key, units FROM stock ORDER BY item_key;
SQL
tb sqlite3 "$DB" <"$SQL"
