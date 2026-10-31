#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh
mysql_db "DROP DATABASE IF EXISTS db_l3_07_shard_strategy; CREATE DATABASE db_l3_07_shard_strategy;"
tb python3 - <<'PY'
import pymysql

orders = [(1, "2026-06-01"), (2, "2026-06-01"), (3, "2026-06-01"),
          (4, "2026-06-01"), (5, "2026-06-01"), (6, "2026-06-01"),
          (7, "2026-06-01"), (8, "2025-12-31")]
conn = pymysql.connect(host="mysql", user="root", password="devbox", database="db_l3_07_shard_strategy", autocommit=True)
with conn.cursor() as cur:
    cur.execute("CREATE TABLE orders (order_id INT PRIMARY KEY, order_day DATE NOT NULL)")
    cur.executemany("INSERT INTO orders VALUES (%s,%s)", orders)
    cur.execute("SELECT order_id, CAST(order_day AS CHAR) FROM orders ORDER BY order_id")
    orders = cur.fetchall()
conn.close()
range_counts = [0] * 4
hash_counts = [0] * 4
for order_id, order_day in orders:
    range_counts[0 if order_day == "2026-06-01" else 1] += 1
    hash_counts[order_id % 4] += 1
print("strategy | shard counts (0,1,2,3)")
print("range-day | " + ",".join(map(str, range_counts)))
print("hash-order-id | " + ",".join(map(str, hash_counts)))
print("range query | one range shard")
print("hash query | all 4 shards")
PY
