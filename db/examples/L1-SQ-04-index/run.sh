#!/usr/bin/env bash
# L1-SQ-04-index · 索引与查询计划
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

DB=/tmp/l1-sq-04-index.db
SQL="$(mktemp)"
trap 'tb rm -f "$DB"; rm -f "$SQL"' EXIT
tb rm -f "$DB"
cat >"$SQL" <<'SQL'
.mode tabs
.headers off
.explain off
CREATE TABLE sales (sale_key TEXT PRIMARY KEY, category TEXT NOT NULL, score INT NOT NULL, active INT NOT NULL);
INSERT INTO sales VALUES
  ('s-1','book',10,1), ('s-2','book',20,1), ('s-3','game',5,0);
CREATE INDEX idx_sales_category_score ON sales(category, score);
CREATE INDEX idx_sales_active_category ON sales(category) WHERE active = 1;
ANALYZE;
SELECT 'covering';
EXPLAIN QUERY PLAN SELECT category, score FROM sales
WHERE category = 'book' ORDER BY score;
SELECT 'partial';
EXPLAIN QUERY PLAN SELECT category FROM sales
WHERE active = 1 AND category = 'book';
SELECT 'table-scan';
EXPLAIN QUERY PLAN SELECT sale_key FROM sales NOT INDEXED
WHERE category = 'book';
SQL
tb sqlite3 "$DB" <"$SQL"
