#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
import redis
from redis.exceptions import WatchError

PREFIX = "l1-rd-07:"
r1 = redis.Redis(host="redis", port=6379, password="devbox", decode_responses=True)
r2 = redis.Redis(host="redis", port=6379, password="devbox", decode_responses=True)
for key in r1.scan_iter(match=PREFIX + "*"):
    r1.unlink(key)
pipe = r1.pipeline()
pipe.multi()
pipe.set(PREFIX + "txn", "ready")
pipe.incr(PREFIX + "count")
result = pipe.execute()
print(f"multi_exec={result[0]},{result[1]}")
discard = r1.pipeline()
discard.multi()
discard.set(PREFIX + "discarded", "no")
discard.discard()
print(f"discarded_key={int(r1.exists(PREFIX + 'discarded'))}")

watch = r1.pipeline()
watch.watch(PREFIX + "watched")
r2.set(PREFIX + "watched", "changed-by-client-2")
watch.multi()
watch.set(PREFIX + "watched", "client-1")
try:
    watch.execute()
except WatchError:
    print("watch_exec=nil (conflict)")
else:
    raise RuntimeError("WATCH transaction unexpectedly committed")
finally:
    watch.reset()
print(f"watched_value={r1.get(PREFIX + 'watched')}")
print(f"lua_atomic_incr={r1.eval("return redis.call('INCR', KEYS[1])", 1, PREFIX + 'lua')}")
r1.close()
r2.close()
PY
)
