#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

SUFFIX="$(date +%s)-$$"
PUB="devbox-db-ex-l3-03-pub-$SUFFIX"
SUB="devbox-db-ex-l3-03-sub-$SUFFIX"
cleanup() { docker rm -f "$PUB" "$SUB" >/dev/null 2>&1 || true; }
trap cleanup EXIT

for spec in "$PUB:wal_level=logical" "$SUB:"; do
  name="${spec%%:*}"
  extra="${spec#*:}"
  args=()
  [ -z "$extra" ] || args+=(-c "$extra")
  docker run -d --name "$name" --network devbox-db_default -e POSTGRES_PASSWORD=devbox -e POSTGRES_HOST_AUTH_METHOD=trust docker.m.daocloud.io/library/postgres:16-alpine postgres "${args[@]}" >/dev/null
done
for name in "$PUB" "$SUB"; do
  ready=0
  for _ in $(seq 1 60); do
    if docker exec "$name" pg_isready -U postgres >/dev/null 2>&1; then ready=1; break; fi
    sleep 1
  done
  [ "$ready" -eq 1 ] || die "PostgreSQL 临时实例未就绪: $name"
done
tb psql -q -h "$PUB" -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE logical_demo" >/dev/null
tb psql -q -h "$SUB" -U postgres -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE logical_demo" >/dev/null
tb psql -q -h "$PUB" -U postgres -d logical_demo -v ON_ERROR_STOP=1 -c "CREATE TABLE events (event_key TEXT PRIMARY KEY, payload TEXT); INSERT INTO events VALUES ('event-1','published'); CREATE PUBLICATION demo_pub FOR TABLE events;" >/dev/null
tb psql -q -h "$SUB" -U postgres -d logical_demo -v ON_ERROR_STOP=1 -c "CREATE TABLE events (event_key TEXT PRIMARY KEY, payload TEXT)" >/dev/null
tb psql -q -h "$SUB" -U postgres -d logical_demo -v ON_ERROR_STOP=1 -c "CREATE SUBSCRIPTION demo_sub CONNECTION 'host=$PUB user=postgres dbname=logical_demo' PUBLICATION demo_pub WITH (copy_data=true)" >/dev/null
tb python3 - <<PY
import psycopg2, time
deadline = time.monotonic() + 60
while time.monotonic() < deadline:
    conn = psycopg2.connect(host="$SUB", user="postgres", dbname="logical_demo")
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM events WHERE event_key='event-1'")
        count = cur.fetchone()[0]
    conn.close()
    if count == 1:
        break
    time.sleep(1)
assert count == 1, count
print("subscription received rows: 1")
PY
