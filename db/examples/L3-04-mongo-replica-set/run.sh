#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

SUFFIX="$(date +%s)-$$"
N1="devbox-db-ex-l3-04-n1-$SUFFIX"
N2="devbox-db-ex-l3-04-n2-$SUFFIX"
N3="devbox-db-ex-l3-04-n3-$SUFFIX"
cleanup() { docker rm -f "$N1" "$N2" "$N3" >/dev/null 2>&1 || true; }
trap cleanup EXIT
for name in "$N1" "$N2" "$N3"; do
  docker run -d --name "$name" --network devbox-db_default docker.m.daocloud.io/library/mongo:7 mongod --replSet db04rs --bind_ip_all >/dev/null
done
tb python3 - <<PY
import pymongo, time
names = ["$N1", "$N2", "$N3"]
clients = [pymongo.MongoClient(f"mongodb://{name}:27017", directConnection=True, serverSelectionTimeoutMS=3000) for name in names]
deadline = time.monotonic() + 60
while time.monotonic() < deadline:
    try:
        for client in clients:
            client.admin.command("ping")
        break
    except Exception:
        time.sleep(1)
else:
    raise RuntimeError("replica set members did not all become ready")
clients[0].admin.command("replSetInitiate", {"_id": "db04rs", "members": [{"_id": i, "host": f"{name}:27017"} for i, name in enumerate(names)]})
deadline = time.monotonic() + 90
primary = None
while time.monotonic() < deadline:
    for client in clients:
        try:
            if client.admin.command("hello").get("isWritablePrimary"):
                primary = client
                break
        except Exception:
            pass
    if primary:
        break
    time.sleep(1)
assert primary is not None, "no elected primary"
# 竞态：刚选完主时 replSetGetStatus 的 members 里可能还没有 self 字段，
# 直接取 member["self"] 会 KeyError。必须轮询到 self.state == 1 为止。
deadline = time.monotonic() + 60
self_member = None
status = None
while time.monotonic() < deadline:
    try:
        status = primary.admin.command("replSetGetStatus")
    except Exception:
        status = None
        time.sleep(1)
        continue
    self_member = next((m for m in status.get("members", []) if m.get("self")), None)
    if self_member is not None and self_member.get("state") == 1:
        break
    self_member = None
    time.sleep(1)
assert self_member is not None, f"replSetGetStatus 里始终没有 self 成员: {status}"
assert self_member.get("state") == 1, self_member
collection = primary["db_l3_04_replica"]["events"].with_options(write_concern=pymongo.write_concern.WriteConcern(w="majority", wtimeout=30000))
collection.insert_one({"event_key": "majority-write", "payload": "committed"})
assert collection.count_documents({"event_key": "majority-write"}) == 1
print("replica set state: PRIMARY")
print("majority write: acknowledged")
for client in clients:
    client.close()
PY
