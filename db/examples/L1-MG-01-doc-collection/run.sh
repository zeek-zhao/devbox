#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
from pymongo import MongoClient

NS = "db_l1_mg_01_doc_collection"
client = MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
client.drop_database(NS)
db = client[NS]
items = db.items
items.insert_one({
    "name": "Ada",
    "age": 37,
    "active": True,
    "profile": {"city": "Suzhou"},
    "team_id": "team-1",
})
db.create_collection("capped_items", capped=True, size=4096, max=2)
capped = db.capped_items
capped.insert_many([{"n": 1}, {"n": 2}, {"n": 3}])

doc = items.find_one({"name": "Ada"}, {"_id": 1, "name": 1, "profile": 1, "team_id": 1})
print(f"_id_type={type(doc['_id']).__name__}")
print(f"python_types={type(doc['profile']).__name__},{type(items.find_one({'name': 'Ada'})['age']).__name__},{type(items.find_one({'name': 'Ada'})['active']).__name__}")
print(f"nested_city={doc['profile']['city']}")
print(f"reference={doc['team_id']}")
print(f"capped={items.database.command('collStats', 'capped_items')['capped']}")
print(f"capped_count={capped.count_documents({})}")
client.close()
PY
)
