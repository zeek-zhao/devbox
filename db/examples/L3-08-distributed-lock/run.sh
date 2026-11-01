#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh
redis_cmd --scan --pattern 'db:l3_08:*' | while IFS= read -r key; do [ -z "$key" ] || redis_cmd UNLINK "$key" >/dev/null; done

tb python3 - <<'PY'
import redis
r = redis.Redis(host="redis", password="devbox", decode_responses=True)
key = "db:l3_08:unsafe"
assert r.set(key, "owner-A", nx=True, px=3000)
assert not r.set(key, "owner-B", nx=True, px=3000)
print("first acquire: A")
print("contended acquire: denied")
import time
time.sleep(3.1)
assert r.set(key, "owner-B", nx=True, px=3000)
r.delete(key)
print("expired A deletes B lock: yes (unsafe DEL)")
safe = "db:l3_08:safe"
assert r.set(safe, "owner-B", nx=True, px=3000)
removed = r.eval("if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end", 1, safe, "owner-A")
assert removed == 0 and r.get(safe) == "owner-B"
print("owner-checked release preserves B lock: yes")
r.delete(key, safe)
PY
