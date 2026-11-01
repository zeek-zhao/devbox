#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
from pymongo import MongoClient
from pymongo.errors import OperationFailure

NS = "db_l1_mg_08_replica_concept"
client = MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
client.drop_database(NS)
try:
    client.admin.command("replSetGetStatus")
except OperationFailure as exc:
    code_name = exc.details.get("codeName")
    if code_name != "NoReplicationEnabled":
        raise
    print(f"replica_status=unavailable ({code_name}, code={exc.code})")
    print("reason=shared MongoDB runs standalone without --replSet")
else:
    raise RuntimeError("expected the shared MongoDB standalone to reject replSetGetStatus")
finally:
    client.drop_database(NS)
    client.close()
PY
)
