#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

NAME="devbox-db-ex-l3-11-$(date +%s)-$$"
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

tb openssl req -x509 -newkey rsa:2048 -nodes -days 1 -keyout "$KEY" -out "$CRT" -subj "/CN=$NAME" -addext "subjectAltName=DNS:$NAME" >/dev/null 2>&1
tb chmod 644 "$KEY"
docker cp "$TOOLBOX:$CRT" "$TMP/server.crt" >/dev/null
docker cp "$TOOLBOX:$KEY" "$TMP/server.key" >/dev/null
chmod 755 "$TMP"
chmod 644 "$TMP/server.crt" "$TMP/server.key"
docker run -d --name "$NAME" --network devbox-db_default -e MYSQL_ROOT_PASSWORD=devbox -v "$TMP:/tls:ro" docker.m.daocloud.io/library/mysql:8.4 --require_secure_transport=ON --ssl-ca=/tls/server.crt --ssl-cert=/tls/server.crt --ssl-key=/tls/server.key >/dev/null
ready=0
for _ in $(seq 1 90); do
  if docker exec "$NAME" mysqladmin ping -h 127.0.0.1 -uroot -pdevbox --silent >/dev/null 2>&1; then ready=1; break; fi
  sleep 1
done
[ "$ready" -eq 1 ] || die "TLS MySQL 临时实例未就绪"
docker cp "$TMP/server.crt" "$TOOLBOX:$CRT" >/dev/null
tb python3 - <<PY
import pymysql
host = "$NAME"
secure = pymysql.connect(host=host, user="root", password="devbox", ssl={"ca": "$CRT", "check_hostname": True}, autocommit=True)
with secure.cursor() as cur:
    cur.execute("SHOW STATUS LIKE 'Ssl_cipher'")
    cipher = cur.fetchone()[1]
assert cipher, cipher
secure.close()
print("TLS cipher: active")
try:
    pymysql.connect(host=host, user="root", password="devbox", ssl_disabled=True, connect_timeout=5)
except pymysql.MySQLError:
    print("plaintext connection: rejected")
else:
    raise AssertionError("plaintext connection unexpectedly succeeded")
PY
