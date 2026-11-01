#!/usr/bin/env bash
# L4-02-composite-index · 复合索引设计
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
NS=db_l4_02_composite_index

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
mysql_db "USE $NS;
CREATE TABLE events (
  id INT NOT NULL PRIMARY KEY,
  tenant_id INT NOT NULL,
  status VARCHAR(8) NOT NULL,
  event_day DATE NOT NULL,
  payload VARCHAR(32) NOT NULL,
  KEY idx_tenant_status_day (tenant_id,status,event_day),
  KEY idx_status_tenant_day (status,tenant_id,event_day),
  KEY idx_tenant_day_status_payload (tenant_id,event_day,status,payload)
);
INSERT INTO events
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<120
)
SELECT n, MOD(n,10), IF(MOD(n,5)=0,'closed','open'),
       DATE_ADD('2026-01-01', INTERVAL MOD(n,12) DAY),
       CONCAT('payload-',n)
FROM seq;
ANALYZE TABLE events;" >/dev/null

echo "index write-width proxy:"
mysql_db "SELECT CONCAT(index_name,': parts=',COUNT(*))
FROM information_schema.statistics
WHERE table_schema='$NS' AND table_name='events' AND index_name<>'PRIMARY'
GROUP BY index_name ORDER BY index_name;"
echo "same query: tenant=1 status=open day=2026-01-03..2026-01-07"
for index in idx_tenant_status_day idx_status_tenant_day idx_tenant_day_status_payload; do
  plan="$(mysql_db "EXPLAIN SELECT tenant_id,status,event_day,payload FROM $NS.events FORCE INDEX ($index) WHERE tenant_id=1 AND status='open' AND event_day >= '2026-01-03' AND event_day < '2026-01-08';")"
  printf '%s\n' "$plan" | awk -F '\t' -v name="$index" \
    '{printf "%s: type=%s key=%s key_len=%s rows=%s extra=%s\n", name, $5, $7, $8, $10, $12}'
done
tenant_plan="$(mysql_db "EXPLAIN SELECT tenant_id FROM $NS.events FORCE INDEX (idx_tenant_status_day) WHERE tenant_id=1;")"
status_plan="$(mysql_db "EXPLAIN SELECT tenant_id FROM $NS.events FORCE INDEX (idx_status_tenant_day) WHERE tenant_id=1;")"
printf 'tenant-only left prefix: tenant-leading type=%s rows=%s; status-leading type=%s rows=%s\n' \
  "$(printf '%s\n' "$tenant_plan" | awk -F '\t' '{print $5}')" \
  "$(printf '%s\n' "$tenant_plan" | awk -F '\t' '{print $10}')" \
  "$(printf '%s\n' "$status_plan" | awk -F '\t' '{print $5}')" \
  "$(printf '%s\n' "$status_plan" | awk -F '\t' '{print $10}')"
