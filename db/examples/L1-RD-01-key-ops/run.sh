#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
import redis

PREFIX = "l1-rd-01:"
r = redis.Redis(host="redis", port=6379, password="devbox", decode_responses=True)
for key in r.scan_iter(match=PREFIX + "*"):
    r.unlink(key)
r.set(PREFIX + "alpha", "one")
r.set(PREFIX + "temporary", "short")
r.expire(PREFIX + "temporary", 60)
print(f"type={r.type(PREFIX + 'alpha')}")
print(f"exists={r.exists(PREFIX + 'alpha')}")
print(f"ttl={'positive' if r.ttl(PREFIX + 'temporary') > 0 else 'invalid'}")
r.persist(PREFIX + "temporary")
print(f"persisted={r.ttl(PREFIX + 'temporary') == -1}")
keys = sorted(key.removeprefix(PREFIX) for key in r.scan_iter(match=PREFIX + "*"))
print(f"scan={','.join(keys)}")
print(f"deleted={r.delete(PREFIX + 'alpha')}")
print(f"exists_after_delete={r.exists(PREFIX + 'alpha')}")
PY
)
