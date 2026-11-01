#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
import redis

PREFIX = "l1-rd-02:"
r = redis.Redis(host="redis", port=6379, password="devbox", decode_responses=True)
for key in r.scan_iter(match=PREFIX + "*"):
    r.unlink(key)
counter = PREFIX + "counter"
print(f"setnx_first={r.setnx(counter, 4)}")
print(f"setnx_second={r.setnx(counter, 9)}")
print(f"getset_old={r.getset(counter, 7)}")
print(f"incr={r.incr(counter)}")
r.set(PREFIX + "text", "Hello")
print(f"append_length={r.append(PREFIX + 'text', ' Redis')}")
r.setrange(PREFIX + "text", 6, "World")
print(f"range={r.getrange(PREFIX + 'text', 0, -1)}")
print(f"set_nx={r.set(PREFIX + 'guard', 'first', nx=True)}")
print(f"set_nx_again={r.set(PREFIX + 'guard', 'second', nx=True)}")
print(f"set_xx={r.set(PREFIX + 'guard', 'updated', xx=True)}")
print(f"guard={r.get(PREFIX + 'guard')}")
PY
)
