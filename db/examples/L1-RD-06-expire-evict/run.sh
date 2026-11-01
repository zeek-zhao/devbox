#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

NAME=devbox-db-ex-l1-rd-06
cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup
docker run -d --rm --name "$NAME" --network devbox-db_default \
  docker.m.daocloud.io/library/redis:7-alpine \
  redis-server --maxmemory 1mb --maxmemory-policy allkeys-lru >/dev/null
for _ in {1..30}; do
  if docker exec "$NAME" redis-cli ping 2>/dev/null | grep -q PONG; then
    break
  fi
  sleep 1
done
docker exec "$NAME" redis-cli ping 2>/dev/null | grep -q PONG || {
  echo "isolated Redis did not become ready" >&2
  exit 1
}
REDIS_IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$NAME")"
[ -n "$REDIS_IP" ] || {
  echo "isolated Redis has no network address" >&2
  exit 1
}
py_file <(sed "s/EX_REDIS_HOST/$REDIS_IP/" <<'PY'
import redis
from redis.exceptions import OutOfMemoryError

PREFIX = "l1-rd-06:"
r = redis.Redis(host="EX_REDIS_HOST", port=6379, decode_responses=True)
for key in r.scan_iter(match=PREFIX + "*"):
    r.unlink(key)
r.config_set("maxmemory", "4mb")
r.set(PREFIX + "ttl", "short", px=5000)
if r.pttl(PREFIX + "ttl") <= 0:
    raise RuntimeError("PEXPIRE did not produce a positive TTL")
print("ttl=positive")
policy = r.config_get("maxmemory-policy")["maxmemory-policy"]
if policy != "allkeys-lru":
    raise RuntimeError(f"unexpected eviction policy: {policy}")
print(f"policy={policy}")
payload = "x" * 32768
for index in range(160):
    r.set(f"{PREFIX}fill:{index}", payload)
r.config_resetstat()
r.config_set("maxmemory", "1mb")
try:
    r.set(PREFIX + "pressure", payload)
except OutOfMemoryError:
    pass
if int(r.info("stats")["evicted_keys"]) <= 0:
    raise RuntimeError("memory pressure did not evict any key")
print("eviction=observed")
PY
)
