#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

SUFFIX="$(date +%s)-$$"
PRIMARY="devbox-db-ex-l3-01-primary-$SUFFIX"
REPLICA="devbox-db-ex-l3-01-replica-$SUFFIX"
cleanup() { docker rm -f "$PRIMARY" "$REPLICA" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "$PRIMARY" --network devbox-db_default -e MYSQL_ROOT_PASSWORD=devbox docker.m.daocloud.io/library/mysql:8.4 --server-id=1 --log-bin=mysql-bin --binlog-format=ROW --gtid-mode=ON --enforce-gtid-consistency=ON >/dev/null
docker run -d --name "$REPLICA" --network devbox-db_default -e MYSQL_ROOT_PASSWORD=devbox docker.m.daocloud.io/library/mysql:8.4 --server-id=2 --relay-log=relay-bin --gtid-mode=ON --enforce-gtid-consistency=ON >/dev/null
for name in "$PRIMARY" "$REPLICA"; do
  ready=0
  for _ in $(seq 1 90); do
    if docker exec "$name" mysqladmin ping -h 127.0.0.1 -uroot -pdevbox --silent >/dev/null 2>&1; then ready=1; break; fi
    sleep 1
  done
  [ "$ready" -eq 1 ] || die "MySQL 临时实例未就绪: $name"
done
tb mysql -h "$PRIMARY" -uroot -pdevbox -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'replpass'; GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'; CREATE DATABASE replication_demo; CREATE TABLE replication_demo.events (event_key VARCHAR(32) PRIMARY KEY, payload VARCHAR(32)); INSERT INTO replication_demo.events VALUES ('order-1','created');"
tb mysql -h "$REPLICA" -uroot -pdevbox -e "CHANGE REPLICATION SOURCE TO SOURCE_HOST='$PRIMARY', SOURCE_USER='repl', SOURCE_PASSWORD='replpass', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1; START REPLICA;"
tb python3 - <<PY
import pymysql, time
host = "$REPLICA"
deadline = time.monotonic() + 60
while time.monotonic() < deadline:
    c = pymysql.connect(host=host, user="root", password="devbox", autocommit=True)
    with c.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute("SHOW REPLICA STATUS")
        status = cur.fetchone()
        try:
            cur.execute("SELECT payload FROM replication_demo.events WHERE event_key='order-1'")
            row = cur.fetchone()
        except pymysql.err.OperationalError as exc:
            if exc.args[0] != 1049:
                raise
            row = None
    c.close()
    if status and status["Replica_IO_Running"] == "Yes" and status["Replica_SQL_Running"] == "Yes" and row:
        break
    time.sleep(1)
assert status and status["Replica_IO_Running"] == "Yes" and status["Replica_SQL_Running"] == "Yes", status
assert row and row["payload"] == "created", row
print("Replica_IO_Running: Yes")
print("Replica_SQL_Running: Yes")
print("replicated row: order-1=created")
PY
