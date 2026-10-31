#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
import redis

PREFIX = "l1-rd-04:"
r = redis.Redis(host="redis", port=6379, password="devbox", decode_responses=True)
for key in r.scan_iter(match=PREFIX + "*"):
    r.unlink(key)
key = PREFIX + "profile"
r.hset(key, mapping={"name": "Ada", "visits": 2, "city": "Suzhou"})
r.hincrby(key, "visits", 3)
fields = sorted(r.hgetall(key).items())
print("hgetall=" + ",".join(f"{field}:{value}" for field, value in fields))
scanned = sorted((field, value) for field, value in r.hscan_iter(key, count=10))
print("hscan=" + ",".join(f"{field}:{value}" for field, value in scanned))
print(f"encoding={r.object("ENCODING", key)}")
print(f"deleted={r.hdel(key, 'city')}")
print(f"fields_after_delete={r.hlen(key)}")
PY
)
