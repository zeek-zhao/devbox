#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
import redis

PREFIX = "l1-rd-03:"
r = redis.Redis(host="redis", port=6379, password="devbox", decode_responses=True)
for key in r.scan_iter(match=PREFIX + "*"):
    r.unlink(key)
key = PREFIX + "items"
r.lpush(key, "b", "a")
r.rpush(key, "c", "d")
print(f"initial={','.join(r.lrange(key, 0, -1))}")
print(f"popped={r.lpop(key)}")
r.linsert(key, "BEFORE", "c", "x")
r.ltrim(key, 0, 2)
print(f"trimmed={','.join(r.lrange(key, 0, -1))}")
print(f"length={r.llen(key)}")
PY
)
