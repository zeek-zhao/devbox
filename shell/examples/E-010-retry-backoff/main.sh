#!/usr/bin/env bash
# 重试与退避：重试是花钱买恢复。预算（次数）、退避（间隔翻倍）、
# 「哪些错误值得重试」都要显式；对不可重试错误重试只会放大故障。
set -euo pipefail

tries=0

flaky_fetch() {
  # 模拟抖动依赖：前 2 次瞬时失败（rc=7，可重试），之后成功。
  tries=$((tries + 1))
  if [ "$tries" -le 2 ]; then
    printf 'flaky-fetch: attempt %d transient failure\n' "$tries" >&2
    return 7
  fi
  return 0
}

always_transient() {
  # 模拟持续故障：每次都瞬时失败。
  tries=$((tries + 1))
  printf 'always-transient: attempt %d failed\n' "$tries" >&2
  return 7
}

quota_denied() {
  # 模拟不可重试失败：配额/权限类（rc=2），重试无意义。
  printf 'quota: denied (permanent)\n' >&2
  return 2
}

retry() {
  # retry <最大次数> <首个间隔毫秒> <命令...>：只在 rc=7（瞬时故障）上重试，
  # 间隔翻倍；不可重试立即停；预算耗尽带着最后一次错误上抛。
  local max="$1" base_ms="$2"
  shift 2
  local waited=0
  local interval="$base_ms"
  local rc=0
  local n=0
  while :; do
    n=$((n + 1))
    if "$@"; then
      rc=0
    else
      rc=$?
    fi
    if [ "$rc" -eq 0 ]; then
      printf 'retry success: attempts=%d waited=%dms\n' "$n" "$waited"
      return 0
    fi
    if [ "$rc" -ne 7 ]; then
      printf 'retry non-retryable: attempts=%d waited=%dms\n' "$n" "$waited"
      return "$rc"
    fi
    if [ "$n" -ge "$max" ]; then
      printf 'retry give-up: attempts=%d waited=%dms\n' "$n" "$waited"
      return "$rc"
    fi
    sleep "0.$(printf '%03d' "$interval")"
    waited=$((waited + interval))
    interval=$((interval * 2))
  done
}

main() {
  local rc=0
  tries=0
  retry 4 10 flaky_fetch || rc=$?
  tries=0
  retry 4 10 quota_denied || rc=$?
  tries=0
  retry 4 10 always_transient || rc=$?
}

main "$@"
