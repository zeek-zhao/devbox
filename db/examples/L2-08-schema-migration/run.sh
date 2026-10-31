#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l2_08_schema_migration

sql_file="$(mktemp)"
trap 'rm -f "$sql_file"' EXIT

if [ "${1:-}" = "--rollback" ]; then
  if [ "$#" -ne 1 ]; then
    die "usage: run.sh [--rollback]"
  fi
  cat >"$sql_file" <<SQL
USE $NS;
ALTER TABLE customers DROP COLUMN display_name;
SELECT CONCAT('rollback schema=', GROUP_CONCAT(column_name ORDER BY ordinal_position))
FROM information_schema.columns
WHERE table_schema = '$NS' AND table_name = 'customers';
SQL
  mysql_file "$sql_file"
  exit 0
fi
if [ "$#" -ne 0 ]; then
  die "usage: run.sh [--rollback]"
fi

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
cat >"$sql_file" <<SQL
USE $NS;
CREATE TABLE customers (
    id integer NOT NULL PRIMARY KEY,
    full_name varchar(80) NOT NULL
);
INSERT INTO customers VALUES
    (1, 'Ada Lovelace'), (2, 'Grace Hopper'), (3, 'Edsger Dijkstra');
SELECT CONCAT('schema before=', GROUP_CONCAT(column_name ORDER BY ordinal_position))
FROM information_schema.columns
WHERE table_schema = '$NS' AND table_name = 'customers';
SELECT CONCAT('rows before=', COUNT(*), ' checksum=',
              MD5(GROUP_CONCAT(CONCAT(id, ':', full_name) ORDER BY id SEPARATOR '|')))
FROM customers;
ALTER TABLE customers ADD COLUMN display_name varchar(80) NULL;
UPDATE customers SET display_name = full_name;
SELECT CONCAT('schema after=', GROUP_CONCAT(column_name ORDER BY ordinal_position))
FROM information_schema.columns
WHERE table_schema = '$NS' AND table_name = 'customers';
SELECT CONCAT('rows after=', COUNT(*), ' unfilled=', SUM(display_name IS NULL))
FROM customers;
SELECT CONCAT(id, ':', display_name) FROM customers ORDER BY id;
SQL
mysql_file "$sql_file"
