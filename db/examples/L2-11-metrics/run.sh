#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh
mysql_db "DROP DATABASE IF EXISTS db_l2_11_metrics; CREATE DATABASE db_l2_11_metrics;"
psql_db "DROP SCHEMA IF EXISTS db_l2_11_metrics CASCADE; CREATE SCHEMA db_l2_11_metrics;" >/dev/null
redis_cmd --scan --pattern 'db:l2_11:*' | while IFS= read -r key; do [ -z "$key" ] || redis_cmd UNLINK "$key" >/dev/null; done

mysql_before="$(mysql_db "SHOW GLOBAL STATUS LIKE 'Com_select';" | awk 'NR==1 {print $2}')"
for _ in $(seq 1 20); do
  mysql_db "SELECT 1;" >/dev/null
done
mysql_after="$(mysql_db "SHOW GLOBAL STATUS LIKE 'Com_select';" | awk 'NR==1 {print $2}')"
[[ "$mysql_before" =~ ^[0-9]+$ && "$mysql_after" =~ ^[0-9]+$ ]] || die "MySQL Com_select counter unavailable"
(( mysql_after - mysql_before >= 10 )) || die "MySQL Com_select did not increase by the required lower bound"
echo "mysql Com_select increased: yes"
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
before = r.info("stats").get("total_commands_processed")
assert isinstance(before, int), "Redis command counter unavailable"
for _ in range(20):
    r.ping()
after = r.info("stats").get("total_commands_processed")
assert isinstance(after, int) and after - before >= 10, "Redis command counter did not reach its lower bound"
print("redis total_commands_processed increased: yes")
r.close()
PY
