#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
import redis

PREFIX = "l1-rd-05:"
r = redis.Redis(host="redis", port=6379, password="devbox", decode_responses=True)
for key in r.scan_iter(match=PREFIX + "*"):
    r.unlink(key)
a, b = PREFIX + "a", PREFIX + "b"
r.sadd(a, "red", "blue", "green")
r.sadd(b, "blue", "green", "yellow")
print(f"intersection={','.join(sorted(r.sinter(a, b)))}")
print(f"union_count={len(r.sunion(a, b))}")
print(f"difference={','.join(sorted(r.sdiff(a, b)))}")
board = PREFIX + "board"
r.zadd(board, {"Ada": 10, "Lin": 20, "Mo": 20, "Zoe": 5})
print("top2=" + ",".join(f"{name}:{score:g}" for name, score in r.zrevrange(board, 0, 1, withscores=True)))
print(f"score_range_count={len(r.zrangebyscore(board, 10, 20))}")
print(f"rank_Ada={r.zrank(board, 'Ada')}")
PY
)
