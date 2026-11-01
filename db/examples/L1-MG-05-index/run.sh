#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
from datetime import datetime

from pymongo import MongoClient

NS = "db_l1_mg_05_index"
client = MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
client.drop_database(NS)
items = client[NS].items
items.insert_many([
    {"_id": "a", "score": 10, "team": "red", "tags": ["x", "y"], "email": "a@example.test", "active": True},
    {"_id": "b", "score": 20, "team": "red", "tags": ["y"], "email": "b@example.test", "active": True},
    {"_id": "c", "score": 30, "team": "blue", "tags": ["z"], "email": "c@example.test", "active": False},
])
items.create_index("score")
items.create_index([("team", 1), ("score", -1)])
items.create_index("tags")
items.create_index("email", unique=True)
items.create_index([("active", 1)], partialFilterExpression={"active": True})
items.create_index("expire_at", expireAfterSeconds=3600)
items.update_many({}, {"$set": {"expire_at": datetime(2099, 1, 1)}})
explain = items.find({"score": {"$gte": 20}}).hint("score_1").explain()
stages = []


def collect_stages(stage):
    if isinstance(stage, dict):
        if "stage" in stage:
            stages.append(stage["stage"])
        for value in stage.values():
            collect_stages(value)
    elif isinstance(stage, list):
        for value in stage:
            collect_stages(value)


collect_stages(explain["queryPlanner"]["winningPlan"])
if "IXSCAN" not in stages:
    raise RuntimeError(f"expected IXSCAN, got {stages}")
print("stage=IXSCAN")
print(f"nReturned={explain['executionStats']['nReturned']}")
print("index_kinds=single,compound,multikey,unique,partial,ttl")
client.close()
PY
)
