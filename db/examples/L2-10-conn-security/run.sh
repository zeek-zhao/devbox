#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

NAME="devbox-db-ex-l2-10-$(date +%s)-$$"
TMP="$(mktemp -d)"
CRT="/tmp/${NAME}.crt"
KEY="/tmp/${NAME}.key"
TOOLBOX="$(dc ps -q toolbox)"
cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker exec "$TOOLBOX" rm -f "$CRT" "$KEY" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

ssl="$(psql_db "SHOW ssl" | tr -d '[:space:]')"
[ "$ssl" = "off" ] || die "共享 PostgreSQL 的 TLS 状态不是 off: $ssl"
echo "shared PostgreSQL TLS: off"

tb openssl req -x509 -newkey rsa:2048 -nodes -days 1 -keyout "$KEY" -out "$CRT" -subj "/CN=$NAME" -addext "subjectAltName=DNS:$NAME" >/dev/null 2>&1
tb chmod 600 "$KEY"
docker cp "$TOOLBOX:$CRT" "$TMP/server.crt" >/dev/null
docker cp "$TOOLBOX:$KEY" "$TMP/server.key" >/dev/null
chmod 755 "$TMP"
chmod 644 "$TMP/server.crt" "$TMP/server.key"
docker run -d --name "$NAME" --network devbox-db_default -e POSTGRES_PASSWORD=devbox -v "$TMP:/tls" --entrypoint sh docker.m.daocloud.io/library/postgres:16-alpine -c 'chown postgres:postgres /tls/server.key; chmod 600 /tls/server.key; exec docker-entrypoint.sh postgres -c ssl=on -c ssl_cert_file=/tls/server.crt -c ssl_key_file=/tls/server.key -c shared_preload_libraries=passwordcheck -c password_encryption=scram-sha-256' >/dev/null
for _ in $(seq 1 60); do
  if docker exec "$NAME" pg_isready -U postgres >/dev/null 2>&1; then break; fi
  sleep 1
done
docker exec "$NAME" pg_isready -U postgres >/dev/null
docker cp "$TMP/server.crt" "$TOOLBOX:$CRT" >/dev/null
secure="$(tb psql "host=$NAME user=postgres dbname=postgres sslmode=verify-full sslrootcert=$CRT" -t -A -c 'SELECT ssl FROM pg_stat_ssl WHERE pid=pg_backend_pid()')"
[ "$secure" = "t" ] || die "临时 PostgreSQL TLS 握手失败"
echo "temporary PostgreSQL TLS: verified"
tb python3 - <<PY
import psycopg2

conn = psycopg2.connect(host="$NAME", user="postgres", dbname="postgres",
                        sslmode="verify-full", sslrootcert="$CRT")
try:
    with conn.cursor() as cur:
        cur.execute("CREATE ROLE weak_password_probe PASSWORD 'short'")
except psycopg2.Error as exc:
    assert exc.pgcode == "22023", exc.pgcode
    print("weak password: rejected")
else:
    raise AssertionError("passwordcheck accepted a short password")
finally:
    conn.close()
PY
