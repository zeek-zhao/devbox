#!/usr/bin/env bash
# L1-MY-08-functions · 常用函数与冷门功能
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_my_08_functions
mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
SQL="$(mktemp)"
trap 'rm -f "$SQL"' EXIT
cat >"$SQL" <<'SQL'
USE db_l1_my_08_functions;
CREATE TABLE products (
  product_key VARCHAR(16) PRIMARY KEY,
  label VARCHAR(32) NOT NULL,
  units INT NOT NULL CHECK (units > 0),
  normalized_label VARCHAR(32) GENERATED ALWAYS AS (LOWER(TRIM(label))) STORED,
  changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT INTO products (product_key, label, units, changed_at)
VALUES ('p-1', '  TeA  ', 2, '2026-01-01 00:00:00');
SELECT CONCAT(UPPER(LEFT(TRIM(label), 1)), SUBSTRING(LOWER(TRIM(label)), 2)),
       DATE_FORMAT(DATE_ADD('2026-01-01', INTERVAL 2 DAY), '%Y-%m-%d'),
       JSON_UNQUOTE(JSON_EXTRACT('{"kind":"drink"}', '$.kind')),
       normalized_label
FROM products WHERE product_key = 'p-1';
UPDATE products SET label = ' COFFEE ' WHERE product_key = 'p-1';
SELECT normalized_label, (changed_at > '2026-01-01 00:00:00')
FROM products WHERE product_key = 'p-1';
SQL
mysql_file "$SQL"
tb python3 - <<'PY'
import pymysql

conn = pymysql.connect(host="mysql", user="root", password="devbox",
                       database="db_l1_my_08_functions")
try:
    with conn.cursor() as cur:
        try:
            cur.execute("INSERT INTO products (product_key, label, units) VALUES ('bad', 'invalid', 0)")
        except pymysql.MySQLError as exc:
            if exc.args[0] != 3819:
                raise
            print(f"check_rejected={exc.args[0]}")
finally:
    conn.close()
PY
