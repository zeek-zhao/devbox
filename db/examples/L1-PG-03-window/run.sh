#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NS=db_l1_pg_03_window
psql_db "DROP DATABASE IF EXISTS $NS" >/dev/null
psql_db "CREATE DATABASE $NS" >/dev/null

sql_file="$(mktemp)"
trap 'rm -f "$sql_file"' EXIT
cat >"$sql_file" <<SQL
\set QUIET 1
\connect $NS
CREATE TABLE scores (
    team text NOT NULL,
    player text NOT NULL,
    points integer NOT NULL,
    PRIMARY KEY (team, player)
);
INSERT INTO scores VALUES
    ('blue', 'Ari', 10), ('blue', 'Bo', 10), ('blue', 'Cy', 7),
    ('red', 'Dee', 9), ('red', 'Eli', 6);
SELECT team, player, points,
       row_number() OVER (PARTITION BY team ORDER BY points DESC, player) AS row_num,
       rank() OVER (PARTITION BY team ORDER BY points DESC) AS rank_num,
       dense_rank() OVER (PARTITION BY team ORDER BY points DESC) AS dense_rank_num
FROM scores
ORDER BY team, points DESC, player;
SQL
psql_file "$sql_file"
