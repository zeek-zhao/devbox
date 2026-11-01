#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
from pymongo import MongoClient
from pymongo.errors import OperationFailure

NS = "db_l1_mg_06_user_role"
USERNAME = "u_l1_mg_06_app"
PASSWORD = "app-password"
client = MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
admin = client.admin
db = client[NS]
try:
    admin.command("dropUser", USERNAME)
except OperationFailure as exc:
    if exc.code != 11:
        raise
try:
    client.drop_database(NS)
    try:
        db.command("dropRole", "l1_mg_06_reader")
    except OperationFailure as exc:
        if exc.details.get("codeName") != "RoleNotFound":
            raise

    db.command(
        "createRole",
        "l1_mg_06_reader",
        privileges=[{"resource": {"db": NS, "collection": ""}, "actions": ["find"]}],
        roles=[],
    )
    admin.command(
        "createUser",
        USERNAME,
        pwd=PASSWORD,
        roles=[{"role": "read", "db": NS}, {"role": "l1_mg_06_reader", "db": NS}],
    )
    info = admin.command("usersInfo", USERNAME, showPrivileges=False)["users"][0]
    roles = sorted(f"{role['role']}@{role['db']}" for role in info["roles"])
    print(f"roles={','.join(roles)}")
    app = MongoClient(
        f"mongodb://{USERNAME}:{PASSWORD}@mongodb:27017/{NS}?authSource=admin",
        serverSelectionTimeoutMS=3000,
    )
    try:
        app[NS].items.insert_one({"_id": "forbidden"})
    except OperationFailure as exc:
        if exc.code != 13:
            raise
        print(f"unauthorized_write=code-{exc.code}")
    else:
        raise RuntimeError("read-only user unexpectedly inserted a document")
    app.close()
finally:
    try:
        admin.command("dropUser", USERNAME)
    except OperationFailure as exc:
        if exc.code != 11:
            raise
    try:
        db.command("dropRole", "l1_mg_06_reader")
    except OperationFailure as exc:
        if exc.details.get("codeName") != "RoleNotFound":
            raise
    client.drop_database(NS)
    client.close()
PY
)
