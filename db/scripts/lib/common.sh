#!/usr/bin/env bash
# db 用例的公共库。
# ------------------------------------------------------------------
# 约定：本文件只定义函数，**绝不能定义 run()** —— bats 内置同名函数，
# 覆盖后所有 `run xxx; [ "$status" -eq 0 ]` 断言会静默失真。
# 另外所有「条件输出」函数在未启用时必须 return 0，否则 set -e 会判失败。
if [[ -n "${_DEVBOX_DB_COMMON:-}" ]]; then return 0; fi
_DEVBOX_DB_COMMON=1

DB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DB_ROOT

# 并行派卡时多张卡共用**同一份** compose 栈：否则不同 worktree 的挂载路径不同，
# docker compose 会认为配置变了而重建 toolbox，把正在跑的其他卡打断。
# 覆盖方式（不进仓库）：$HOME/.devbox-db-compose 里写一份 compose 文件的绝对路径。
if [ -z "${DB_COMPOSE_FILE:-}" ] && [ -f "$HOME/.devbox-db-compose" ]; then
  DB_COMPOSE_FILE="$(cat "$HOME/.devbox-db-compose")"
fi
DB_COMPOSE_FILE="${DB_COMPOSE_FILE:-$DB_ROOT/docker/docker-compose.yml}"
export DB_COMPOSE_FILE

dc() { docker compose -f "$DB_COMPOSE_FILE" "$@"; }
tb() { dc exec -T toolbox "$@"; }

# 每个用例在自己的命名空间里操作，并在开始时清理，保证可重复运行
mysql_file() { tb mysql -h mysql -uroot -N -B < "$1"; }
mysql_db()   { tb mysql -h mysql -uroot -N -B -e "$1"; }
psql_file()  { tb psql -h postgres -U devbox -d devbox -t -A -v ON_ERROR_STOP=1 -f - < "$1"; }
psql_db()    { tb psql -h postgres -U devbox -d devbox -t -A -v ON_ERROR_STOP=1 -c "$1"; }
redis_file() { tb redis-cli -h redis -a devbox --no-auth-warning < "$1"; }
redis_cmd()  { tb redis-cli -h redis -a devbox --no-auth-warning "$@"; }
sqlite_file(){ tb sqlite3 /tmp/db-example.db < "$1"; }
py_file()    { tb python3 - < "$1"; }

# 用例的输出必须是确定的：不打印耗时、不打印时间戳、查询必须显式 ORDER BY
die() { echo "ERROR: $*" >&2; exit 1; }
