#!/usr/bin/env bash
# 等五个服务都真的能接受查询（不是「容器起来了」）
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
. scripts/lib/common.sh

deadline=$(( $(date +%s) + ${DB_WAIT_TIMEOUT:-180} ))
probe() {
  tb mysql -h mysql -uroot -N -B -e 'SELECT 1' >/dev/null 2>&1 || return 1
  tb psql -h postgres -U devbox -d devbox -t -A -c 'SELECT 1' >/dev/null 2>&1 || return 1
  tb redis-cli -h redis -a devbox --no-auth-warning ping >/dev/null 2>&1 || return 1
  tb python3 -c "import pymongo,sys; pymongo.MongoClient('mongodb://devbox:devbox@mongodb:27017/?authSource=admin',serverSelectionTimeoutMS=3000).admin.command('ping'); sys.exit(0)" >/dev/null 2>&1 || return 1
  tb sqlite3 -version >/dev/null 2>&1 || return 1
  return 0
}

while :; do
  if probe; then echo "全部服务就绪"; exit 0; fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "等待超时（${DB_WAIT_TIMEOUT:-180}s），当前状态：" >&2
    dc ps >&2 || true
    exit 1
  fi
  sleep 2
done
