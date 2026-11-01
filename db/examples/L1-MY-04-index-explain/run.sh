#!/usr/bin/env bash
# L1-MY-04-index-explain · 索引与执行计划
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_my_04_index_explain
SQL="$(mktemp)"
trap 'rm -f "$SQL"' EXIT

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
cat >"$SQL" <<'SQL'
USE db_l1_my_04_index_explain;
CREATE TABLE inventory (
  category VARCHAR(16) NOT NULL,
  sku VARCHAR(16) NOT NULL,
  stock INT NOT NULL,
  PRIMARY KEY (category, sku),
  KEY idx_category_sku (category, sku)
);
INSERT INTO inventory VALUES
  ('book','b-1',4), ('book','b-2',7), ('game','g-1',2);
ANALYZE TABLE inventory;
SQL
mysql_file "$SQL" >/dev/null
cat >"$SQL" <<'SQL'
USE db_l1_my_04_index_explain;
EXPLAIN SELECT category, sku FROM inventory FORCE INDEX (idx_category_sku)
WHERE category = 'book';
SQL
echo "indexed category lookup"
mysql_file "$SQL" | awk '{ print $5 "\t" $7 }'
cat >"$SQL" <<'SQL'
USE db_l1_my_04_index_explain;
EXPLAIN SELECT category, sku FROM inventory IGNORE INDEX (PRIMARY, idx_category_sku)
WHERE category = 'book';
SQL
echo "index disabled"
mysql_file "$SQL" | awk '{ print $5 "\t" $7 }'
cat >"$SQL" <<'SQL'
USE db_l1_my_04_index_explain;
EXPLAIN SELECT category, sku, stock FROM inventory
WHERE sku = 'b-1';
SQL
echo "leftmost prefix skipped"
mysql_file "$SQL" | awk '{ print $5 "\t" $7 }'
