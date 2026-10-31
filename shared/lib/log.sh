#!/usr/bin/env bash
# 通用日志库。source 之后可用：
#   log_debug  log_info  log_warn  log_error  log_success  log_section
#   die <msg>            打印 ERROR 并 exit 1
#   log_run <cmd...>     先打印 "+ cmd" 再执行（保留命令自己的退出码）
#
# 约定：
#   * 全部输出走 stderr，stdout 留给调用者的数据。这样才能写 `x=$(json_read ...)`。
#   * 日志前缀是 "[时间戳][级别] "，行首固定，方便 grep / 断言。
#   * 设 NO_COLOR=1 关掉颜色（写文件、进 CI 日志时更干净）。
#   * LOG_DEBUG 非空才输出 debug。未设置时 log_debug 返回 0 而不是 1 ——
#     否则 `set -e` 或 bats 会把「没有 debug 日志」当成失败。
#
# 不要在这里定义名为 run 的函数：bats 内置同名函数，会被整个覆盖掉，
# 结果是所有 `run xxx` 断言静默错乱。历史上踩过一次，见 README「坑位」。
#
# 本文件可以重复 source，第二次直接 return。

if [[ -n "${_DEVBOX_LOG_SH:-}" ]]; then
  return 0
fi
_DEVBOX_LOG_SH=1

if [[ -n "${NO_COLOR:-}" ]]; then
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  PURPLE=''
  CYAN=''
  NC=''
else
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'
  PURPLE=$'\033[0;35m'
  CYAN=$'\033[0;36m'
  NC=$'\033[0m'
fi

LOG_TS_FMT="${LOG_TS_FMT:-%Y-%m-%d %H:%M:%S}"

_log_base() { # level message...
  local lvl="$1"
  shift
  local ts
  ts="$(date +"$LOG_TS_FMT")"
  printf '[%s][%s] %s\n' "$ts" "$lvl" "$*" >&2
}

log_success() { _log_base "${GREEN}SUCCESS${NC}" "$@"; }
log_info() { _log_base "${BLUE}INFO${NC}" "$@"; }
log_warn() { _log_base "${YELLOW}WARN${NC}" "$@"; }
log_error() { _log_base "${RED}ERROR${NC}" "$@"; }

log_debug() {
  [[ -n "${LOG_DEBUG:-}" ]] || return 0
  _log_base "${PURPLE}DEBUG${NC}" "$@"
}

log_section() {
  printf '%s\n' "${CYAN}==================== $* ====================${NC}" >&2
}

die() {
  log_error "$@"
  exit 1
}

log_run() {
  log_info "+ $*"
  "$@"
}
