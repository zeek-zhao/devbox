#!/usr/bin/env bash
# L1-MY-03-join-group · 多表连接与分组
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_my_03_join_group
SQL="$(mktemp)"
trap 'rm -f "$SQL"' EXIT

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
cat >"$SQL" <<'SQL'
USE db_l1_my_03_join_group;
CREATE TABLE teams (team_key VARCHAR(16) PRIMARY KEY);
CREATE TABLE members (
  member_key VARCHAR(16) PRIMARY KEY,
  team_key VARCHAR(16) NOT NULL,
  score INT NOT NULL
);
INSERT INTO teams VALUES ('blue'), ('green'), ('red');
INSERT INTO members VALUES
  ('aya','blue',4), ('bo','blue',7), ('cy','green',5);
SELECT 'LEFT JOIN';
SELECT t.team_key, IFNULL(m.member_key, '-'), IFNULL(CAST(m.score AS CHAR), 'NULL')
FROM teams AS t
LEFT JOIN members AS m ON m.team_key = t.team_key
ORDER BY t.team_key, m.member_key;
SELECT 'GROUP BY';
SELECT t.team_key, COUNT(*) AS joined_rows, COUNT(m.member_key) AS member_count,
       GROUP_CONCAT(m.member_key ORDER BY m.member_key SEPARATOR ',')
FROM teams AS t
LEFT JOIN members AS m ON m.team_key = t.team_key
GROUP BY t.team_key
HAVING COUNT(m.member_key) > 0
ORDER BY t.team_key;
SQL
mysql_file "$SQL"
