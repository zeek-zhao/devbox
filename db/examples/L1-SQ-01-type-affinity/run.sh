#!/usr/bin/env bash
# L1-SQ-01-type-affinity · 类型亲和性
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

DB=/tmp/l1-sq-01-type-affinity.db
SQL="$(mktemp)"
trap 'tb rm -f "$DB"; rm -f "$SQL"' EXIT
tb rm -f "$DB"
cat >"$SQL" <<'SQL'
.mode tabs
.headers off
CREATE TABLE affinity_values (
  row_key TEXT PRIMARY KEY,
  integer_value INTEGER,
  text_value TEXT,
  real_value REAL,
  numeric_value NUMERIC,
  blob_value BLOB,
  no_type
);
INSERT INTO affinity_values VALUES ('text', '123', '123', '123', '123', '123', '123');
INSERT INTO affinity_values VALUES ('integer', 123, 123, 123, 123, 123, 123);
SELECT row_key, typeof(integer_value), typeof(text_value), typeof(real_value),
       typeof(numeric_value), typeof(blob_value), typeof(no_type)
FROM affinity_values ORDER BY row_key;
CREATE TABLE strict_values (value INTEGER) STRICT;
INSERT INTO strict_values VALUES ('123');
SELECT 'strict', typeof(value) FROM strict_values ORDER BY value;
SELECT 'blob-literal', typeof(x'4142');
SQL
tb sqlite3 "$DB" <"$SQL"
