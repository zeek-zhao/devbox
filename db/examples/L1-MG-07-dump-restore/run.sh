#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
import json
import tempfile

from bson import json_util
from pymongo import MongoClient

SOURCE = "db_l1_mg_07_dump_restore"
RESTORED = "db_l1_mg_07_dump_restore_restored"
client = MongoClient("mongodb://devbox:devbox@mongodb:27017/?authSource=admin")
client.drop_database(SOURCE)
client.drop_database(RESTORED)
source = client[SOURCE].records
source.insert_many([
    {"_id": "r1", "group": "keep", "value": 10},
    {"_id": "r2", "group": "keep", "value": 20},
    {"_id": "r3", "group": "skip", "value": 30},
])
with tempfile.NamedTemporaryFile(mode="w+", encoding="utf-8") as dump:
    for doc in source.find({"group": "keep"}).sort("_id", 1):
        dump.write(json_util.dumps(doc) + "\n")
    dump.seek(0)
    restored = client[RESTORED].records
    restored.insert_many([json_util.loads(line) for line in dump if line.strip()])

collections = sorted(client[RESTORED].list_collection_names())
print(f"restored_count={restored.count_documents({})}")
print(f"collections={','.join(collections)}")
print(f"restored_values={','.join(str(row['value']) for row in restored.find({}, {'value': 1, '_id': 0}).sort('value', 1))}")
client.drop_database(SOURCE)
client.drop_database(RESTORED)
client.close()
PY
)
