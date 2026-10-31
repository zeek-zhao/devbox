#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

db=db_l3_02_mysql_partition
mysql_db "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db; USE $db; CREATE TABLE events (event_date DATE NOT NULL, event_name VARCHAR(32) NOT NULL) PARTITION BY RANGE COLUMNS(event_date) (PARTITION p2025 VALUES LESS THAN ('2026-01-01'), PARTITION p2026 VALUES LESS THAN ('2027-01-01'), PARTITION pmax VALUES LESS THAN (MAXVALUE)); INSERT INTO events VALUES ('2025-12-31','old'),('2026-06-01','current'),('2027-01-01','future');"
plan="$(mysql_db "EXPLAIN SELECT event_name FROM $db.events WHERE event_date='2026-06-01'")"
partition="$(printf '%s\n' "$plan" | awk -F '\t' 'NR==1 {print $4}')"
[ "$partition" = "p2026" ] || die "分区裁剪未命中 p2026: $plan"
echo "pruned partition: $partition"
mysql_db "SELECT event_name FROM $db.events WHERE event_date='2026-06-01' ORDER BY event_name;"
