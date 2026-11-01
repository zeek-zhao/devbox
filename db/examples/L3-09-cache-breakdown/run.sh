#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh
mysql_db "DROP DATABASE IF EXISTS db_l3_09_cache_breakdown; CREATE DATABASE db_l3_09_cache_breakdown; CREATE TABLE db_l3_09_cache_breakdown.known_ids (id INT PRIMARY KEY); INSERT INTO db_l3_09_cache_breakdown.known_ids VALUES (1);"
redis_cmd --scan --pattern 'db:l3_09:*' | while IFS= read -r key; do [ -z "$key" ] || redis_cmd UNLINK "$key" >/dev/null; done
tb python3 - <<'PY'
import redis
import pymysql
import threading

r = redis.Redis(host="redis", password="devbox", decode_responses=True)
prefix = "db:l3_09:"
misses = 10
db = pymysql.connect(host="mysql", user="root", password="devbox", database="db_l3_09_cache_breakdown", autocommit=True)
with db.cursor() as cur:
    db_without_negative_cache = 0
    for _ in range(misses):
        cur.execute("SELECT id FROM known_ids WHERE id=99")
        db_without_negative_cache += 1
    db_with_negative_cache = 0
    for _ in range(misses):
        cached = r.get(prefix + "negative:missing")
        if cached is None:
            cur.execute("SELECT id FROM known_ids WHERE id=99")
            db_with_negative_cache += 1
            r.set(prefix + "negative:missing", "EMPTY", ex=60)
        else:
            assert cached == "EMPTY"
db.close()
assert db_without_negative_cache == misses and db_with_negative_cache == 1
print(f"penetration DB reads: {db_without_negative_cache} -> {db_with_negative_cache}")

hot = prefix + "hot"
r.delete(hot)
assert not r.exists(hot)
readers = 8
unlocked_rebuilds = readers
lock_key = prefix + "rebuild-lock"
barrier = threading.Barrier(readers)
winners = []
def acquire(index):
    client = redis.Redis(host="redis", password="devbox")
    barrier.wait()
    if client.set(lock_key, str(index), nx=True, px=3000):
        winners.append(index)
    client.close()
workers = [threading.Thread(target=acquire, args=(i,)) for i in range(readers)]
for worker in workers:
    worker.start()
for worker in workers:
    worker.join()
locked_rebuilds = len(winners)
assert locked_rebuilds == 1, locked_rebuilds
r.set(hot, "value", ex=60)
r.delete(lock_key)
print(f"breakdown concurrent DB rebuilds: {unlocked_rebuilds} -> {locked_rebuilds}")

for i in range(4):
    r.set(prefix + f"aligned:{i}", "v", ex=60)
    r.set(prefix + f"jittered:{i}", "v", ex=100 + i * 10)
aligned_ttls = [r.ttl(prefix + f"aligned:{i}") for i in range(4)]
jittered_ttls = [r.ttl(prefix + f"jittered:{i}") for i in range(4)]
aligned_cohort = max(aligned_ttls.count(ttl) for ttl in set(aligned_ttls))
jittered_cohort = max(jittered_ttls.count(ttl) for ttl in set(jittered_ttls))
assert aligned_cohort == 4 and jittered_cohort == 1, (aligned_ttls, jittered_ttls)
print(f"avalanche same-expiry cohort: {aligned_cohort} -> {jittered_cohort}")
keys = list(r.scan_iter(prefix + "*"))
if keys:
    r.delete(*keys)
PY
