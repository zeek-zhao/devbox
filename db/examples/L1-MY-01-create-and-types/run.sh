#!/usr/bin/env bash
# L1-MY-01-create-and-types · 建表与数据类型
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_my_01_create_and_types
SQL="$(mktemp)"
trap 'rm -f "$SQL"' EXIT

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
cat >"$SQL" <<'SQL'
USE db_l1_my_01_create_and_types;
CREATE TABLE numeric_types (
  item_code CHAR(4) PRIMARY KEY,
  quantity SMALLINT UNSIGNED NOT NULL,
  price DECIMAL(10,2) NOT NULL
) CHARACTER SET utf8mb4;
CREATE TABLE text_types (
  item_code CHAR(4) PRIMARY KEY,
  label VARCHAR(24) NOT NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE TABLE enum_types (
  item_code CHAR(4) PRIMARY KEY,
  state ENUM('new','ready') NOT NULL
) CHARACTER SET utf8mb4;
CREATE TABLE varchar_types (
  item_code CHAR(4) PRIMARY KEY,
  state VARCHAR(8) NOT NULL
) CHARACTER SET utf8mb4;
SELECT table_name, column_name, column_type, IFNULL(character_set_name, '-')
FROM information_schema.columns
WHERE table_schema = 'db_l1_my_01_create_and_types'
ORDER BY table_name, ordinal_position;
SQL
mysql_file "$SQL"
