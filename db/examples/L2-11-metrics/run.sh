#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh
mysql_db "DROP DATABASE IF EXISTS db_l2_11_metrics; CREATE DATABASE db_l2_11_metrics;"
psql_db "DROP SCHEMA IF EXISTS db_l2_11_metrics CASCADE; CREATE SCHEMA db_l2_11_metrics;" >/dev/null
redis_cmd --scan --pattern 'db:l2_11:*' | while IFS= read -r key; do [ -z "$key" ] || redis_cmd UNLINK "$key" >/dev/null; done

mysql_db "SELECT CONCAT('mysql metrics: ', IF(COUNT(*)=2,'available','missing')) FROM performance_schema.global_status WHERE VARIABLE_NAME IN ('Connections','Queries');"
psql_db "SELECT 'postgres metrics: ' || CASE WHEN stats_reset IS NOT NULL OR numbackends >= 0 THEN 'available' ELSE 'missing' END FROM pg_stat_database WHERE datname=current_database();"
tb python3 - <<'PY'
import pymongo
client = pymongo.MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin", serverSelectionTimeoutMS=5000)
status = client.admin.command("serverStatus")
assert "connections" in status and "opcounters" in status
print("mongodb metrics: available")
client.close()
PY
tb python3 - <<'PY'
import redis
r = redis.Redis(host="redis", password="devbox", decode_responses=True)
info = r.info("stats")
assert "total_commands_processed" in info and "keyspace_hits" in info
r.set("db:l2_11:probe", "1")
print("redis metrics: stats/hit counters available")
r.delete("db:l2_11:probe")
PY
