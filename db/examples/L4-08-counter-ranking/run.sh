#!/usr/bin/env bash
# L4-08-counter-ranking · 计数与排行榜
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
script="$(mktemp)"
trap 'rm -f "$script"' EXIT

cat >"$script" <<'PY'
import os
import sqlite3

import redis

path = "/tmp/l4_08_counter_ranking.db"
if os.path.exists(path):
    os.remove(path)
source = sqlite3.connect(path)
source.execute("CREATE TABLE scores (player TEXT PRIMARY KEY, score INTEGER NOT NULL)")
source.executemany("INSERT INTO scores VALUES (?,?)",
                   [("alice", 120), ("bob", 120), ("carol", 95), ("dave", 80)])
source.commit()
r = redis.Redis(host="redis", password="devbox", decode_responses=True)
key = "l4_08_counter_ranking:board"
for old_key in r.scan_iter(match="l4_08_counter_ranking:*"):
    r.unlink(old_key)

def rebuild():
    r.delete(key)
    for player, score in source.execute(
            "SELECT player,score FROM scores ORDER BY score,player"):
        r.zadd(key, {player: score})

rebuild()
page = r.zrevrange(key, 0, 2, withscores=True)
print("top-3: " + ",".join(f"{name}:{int(score)}" for name, score in page))
print(f"alice rank-from-top={r.zrevrank(key, 'alice') + 1}")
r.delete(key)
rebuild()
print("after DB rebuild: " + ",".join(
    f"{name}:{int(score)}" for name, score in r.zrevrange(key, 0, -1, withscores=True)))
source.close()
os.remove(path)
PY
py_file "$script"
