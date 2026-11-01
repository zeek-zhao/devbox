#!/usr/bin/env bash
# L4-03-cache-pattern · 缓存一致性模式
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
NS=db_l4_03_cache_pattern
script="$(mktemp)"
trap 'rm -f "$script"' EXIT

mysql_db "DROP DATABASE IF EXISTS $NS; CREATE DATABASE $NS;"
cat >"$script" <<'PY'
import concurrent.futures
import threading
import time

import pymysql
import redis

db = pymysql.connect(host="mysql", user="root", password="devbox",
                     database="db_l4_03_cache_pattern", autocommit=True)
r = redis.Redis(host="redis", password="devbox", decode_responses=True)
prefix = "l4_03_cache_pattern:"
for key in r.scan_iter(match=prefix + "*"):
    r.unlink(key)
with db.cursor() as cur:
    cur.execute("CREATE TABLE state (mode VARCHAR(16) PRIMARY KEY, version INT NOT NULL, value VARCHAR(16) NOT NULL)")
    for mode in ("aside", "through", "behind"):
        cur.execute("INSERT INTO state VALUES (%s,0,'old')", (mode,))

def write(mode, version, barrier):
    barrier.wait()
    value = f"value-{version}"
    writer_db = pymysql.connect(host="mysql", user="root", password="devbox",
                                database="db_l4_03_cache_pattern",
                                autocommit=True)
    with writer_db.cursor() as cur:
        cur.execute(
            "UPDATE state SET value=IF(%s>version,%s,value), "
            "version=GREATEST(version,%s) WHERE mode=%s",
            (version, value, version, mode),
        )
    writer_db.close()
    if mode == "aside":
        r.delete(prefix + mode)
    elif mode == "through":
        r.eval(
            "local old=redis.call('GET',KEYS[1]); "
            "local v=old and tonumber(string.match(old,'^(%d+):')) or -1; "
            "if tonumber(ARGV[1])>v then redis.call('SET',KEYS[1],ARGV[1]..':'..ARGV[2]); end; "
            "return 1",
            1, prefix + mode, version, value,
        )
    else:
        r.zadd(prefix + "queue", {f"{version}:{value}": version})

for mode in ("aside", "through", "behind"):
    r.set(prefix + mode, "0:old")
    barrier = threading.Barrier(3)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(write, mode, version, barrier)
                   for version in (1, 2)]
        barrier.wait()
        for future in futures:
            future.result()
    if mode == "aside":
        with db.cursor() as cur:
            cur.execute("SELECT version,value FROM state WHERE mode=%s", (mode,))
            version, value = cur.fetchone()
        r.set(prefix + mode, f"{version}:{value}")
    elif mode == "behind":
        for item, _ in r.zrange(prefix + "queue", 0, -1, withscores=True):
            version, value = item.split(":", 1)
            with db.cursor() as cur:
                cur.execute("UPDATE state SET version=%s,value=%s WHERE mode=%s",
                            (int(version), value, mode))
            r.set(prefix + mode, item)
    with db.cursor() as cur:
        cur.execute("SELECT version,value FROM state WHERE mode=%s", (mode,))
        version, value = cur.fetchone()
    cached = r.get(prefix + mode).split(":", 1)[1]
    print(f"{mode}: db={value}@{version} cache={cached}")

with db.cursor() as cur:
    cur.execute("SELECT version,value FROM state WHERE mode='aside'")
    version, value = cur.fetchone()
r.set(prefix + "aside", f"{version}:{value}", ex=1)
time.sleep(1.1)
if r.get(prefix + "aside") is None:
    with db.cursor() as cur:
        cur.execute("SELECT version,value FROM state WHERE mode='aside'")
        version, value = cur.fetchone()
    r.set(prefix + "aside", f"{version}:{value}")
    print(f"aside TTL miss: db={value}@{version} cache={value}")
db.close()
PY
py_file "$script"
