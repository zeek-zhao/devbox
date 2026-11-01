#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh
mysql_db "DROP DATABASE IF EXISTS db_l2_15_db_selection; CREATE DATABASE db_l2_15_db_selection;"
cat <<'TABLE'
store | order write | cache/log use | trade-off
MySQL | L1-MY-02 CRUD | L4-03 cache; L3-12 audit | joins and transactions; schema changes require planning
PostgreSQL | L1-PG-02 RETURNING | L4-03 cache; L3-03 change feed | strong SQL and JSONB; operations need a server
MongoDB | L1-MG-02 CRUD | L4-03 cache; L2-02 profiler | flexible documents; cross-document joins cost more
Redis | L1-RD-02 string | L3-09 cache; L3-05 AOF | fast cache/ranking; persistence is not an order ledger
SQLite | L1-SQ-02 CRUD | L4-03 cache; L1-SQ-05 trigger log | embedded and simple; one writer limits concurrent writes
TABLE
