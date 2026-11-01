#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l2_03_index_not_used
mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"

sql_file="$(mktemp)"
trap 'rm -f "$sql_file"' EXIT
cat >"$sql_file" <<SQL
USE $NS;
CREATE TABLE events (
    id integer NOT NULL PRIMARY KEY,
    created_at datetime NOT NULL,
    code varchar(8) NOT NULL,
    category varchar(12) NOT NULL,
    payload varchar(32) NOT NULL,
    active tinyint NOT NULL,
    KEY events_created_at_idx (created_at),
    KEY events_code_idx (code),
    KEY events_category_idx (category),
    KEY events_payload_idx (payload),
    KEY events_active_idx (active)
);
INSERT INTO events
WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL SELECT n + 1 FROM seq WHERE n < 1000
)
SELECT n,
       TIMESTAMPADD(DAY, n, '2026-01-01 00:00:00'),
       LPAD(n, 6, '0'),
       IF(n = 997, 'rare', 'common'),
       IF(n = 997, 'needle', 'hay'),
       IF(n < 990, 1, 0)
FROM seq;
ANALYZE TABLE events;
SELECT 'date direct';
EXPLAIN SELECT id FROM events
WHERE created_at >= '2026-01-10' AND created_at < '2026-01-11';
SELECT 'date wrapped';
EXPLAIN SELECT id FROM events WHERE DATE(created_at) = '2026-01-10';
SELECT 'string key direct';
EXPLAIN SELECT id FROM events WHERE code = '000123';
SELECT 'implicit numeric conversion';
EXPLAIN SELECT id FROM events WHERE code = 123;
SELECT 'prefix pattern';
EXPLAIN SELECT id FROM events WHERE payload LIKE 'needle%';
SELECT 'leading wildcard';
EXPLAIN SELECT id FROM events WHERE payload LIKE '%needle';
SELECT 'OR mixed';
EXPLAIN SELECT id FROM events WHERE category = 'rare' OR payload = 'needle';
SELECT 'UNION rewrite';
EXPLAIN SELECT id FROM events WHERE category = 'rare'
UNION
SELECT id FROM events WHERE id = 997;
SELECT 'low selectivity';
EXPLAIN SELECT payload FROM events WHERE active = 1;
SELECT 'forced low-selectivity index';
EXPLAIN SELECT payload FROM events FORCE INDEX (events_active_idx) WHERE active = 1;
SQL
mysql_file "$sql_file" | awk -F '\t' '
  NF == 1 { label = $1; next }
  NF >= 7 && $1 ~ /^[0-9]+$/ {
    key = $7 == "" ? "none" : $7
    printf "%s type=%s key=%s\n", label, $5, key
  }
'
