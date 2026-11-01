#!/usr/bin/env bash
set -euo pipefail
# 失败时报出「第几行、哪条命令」——没有这个，静默失败（命令自己吞了 stderr）
# 在 CI 上就只剩一行 FAIL，查不出来。
trap 'echo "ERROR: 第 $LINENO 行失败: $BASH_COMMAND" >&2' ERR
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

# 只静默 stdout（openssl 会往 stdout 打进度点）；stderr 必须留着，
# 否则自签证书失败时现场一片空白。
tb openssl req -x509 -newkey rsa:2048 -nodes -days 1 -keyout "$KEY" -out "$CRT" -subj "/CN=$NAME" -addext "subjectAltName=DNS:$NAME" >/dev/null
tb chmod 600 "$KEY"
docker cp "$TOOLBOX:$CRT" "$TMP/server.crt" >/dev/null
docker cp "$TOOLBOX:$KEY" "$TMP/server.key" >/dev/null
chmod 755 "$TMP"
chmod 644 "$TMP/server.crt" "$TMP/server.key"
docker run -d --name "$NAME" --network devbox-db_default -e POSTGRES_PASSWORD=devbox -v "$TMP:/tls" --entrypoint sh docker.m.daocloud.io/library/postgres:16-alpine -c 'chown postgres:postgres /tls/server.key; chmod 600 /tls/server.key; exec docker-entrypoint.sh postgres -c ssl=on -c ssl_cert_file=/tls/server.crt -c ssl_key_file=/tls/server.key -c shared_preload_libraries=passwordcheck -c password_encryption=scram-sha-256' >/dev/null
# 等真实服务就绪。这里刻意不是「循环里 break + 循环外单次断言」的写法：
# 那种写法在 CI 上偶发失败过一次（同一提交前两轮全绿，第三轮红），
# 而失败现场只有一行 FAIL，看不出容器到底是没起来、起来了又退出、还是只是抖了一下。
# 三处收紧：
#   1) 走 TCP（-h 127.0.0.1）而不是默认的 unix socket，避免把 initdb 阶段的
#      临时服务当成「已就绪」；
#   2) 要求连续 3 次成功，而不是成功一次就 break —— 服务重启间隙里的一次误判
#      不该放行，也不该让后面的断言替它背锅；
#   3) 超时后把容器状态、退出码和日志一起打出来，让下一次失败能自证。
ready=0
ok=0
for _ in $(seq 1 60); do
  if docker exec "$NAME" pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1; then
    ok=$((ok + 1))
    if [ "$ok" -ge 3 ]; then ready=1; break; fi
  else
    ok=0
  fi
  sleep 1
done
if [ "$ready" -ne 1 ]; then
  echo "临时 PostgreSQL 60 秒内未稳定就绪。容器状态与日志：" >&2
  docker inspect -f 'status={{.State.Status}} exit={{.State.ExitCode}}' "$NAME" >&2 || true
  docker logs "$NAME" 2>&1 | tail -25 >&2 || true
  die "临时 PostgreSQL 未就绪"
fi
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
