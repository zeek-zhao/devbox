#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

NAME="devbox-db-ex-l3-05-$(date +%s)-$$"
cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT
docker run -d --name "$NAME" --network devbox-db_default docker.m.daocloud.io/library/redis:7-alpine redis-server --appendonly yes --appendfsync always >/dev/null
for _ in $(seq 1 30); do
  if tb redis-cli -h "$NAME" PING >/dev/null 2>&1; then break; fi
  sleep 1
done
tb redis-cli -h "$NAME" SET db:l3_05:persisted durable >/dev/null
docker exec "$NAME" redis-cli SHUTDOWN || true
running="$(docker inspect -f '{{.State.Running}}' "$NAME")"
[ "$running" = "false" ] || die "Redis SHUTDOWN 没有停止临时实例"
docker start "$NAME" >/dev/null
for _ in $(seq 1 30); do
  if tb redis-cli -h "$NAME" GET db:l3_05:persisted >/dev/null 2>&1; then break; fi
  sleep 1
done
value="$(tb redis-cli -h "$NAME" --raw GET db:l3_05:persisted)"
[ "$value" = "durable" ] || die "AOF 重启后未恢复 key"
echo "AOF restart recovery: key persisted"
