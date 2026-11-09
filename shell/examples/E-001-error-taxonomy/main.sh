#!/usr/bin/env bash
# 错误分类与类型体系：先定义一套封闭的退出码枚举，再给每个码一个唯一的稳定分类。
# 分类（而不是具体码）决定处理策略：
#   usage       —— 调用方 bug，修调用，不重试；
#   environment —— 外部状态，可重试或上报；
#   internal    —— 程序前提被破坏，快速失败。
# 没有这套体系时，同一个退出码在不同调用点会被随意解读。
set -euo pipefail

# 封闭的退出码枚举：0 成功；2 用法错误；3 输入缺失；4 依赖工具缺失；5 内部前提被破坏。
probe_codes() {
  # 逐个码模拟一次失败来源（真脚本里这些来自真实命令的退出码）。
  printf '%s\n' 0 2 3 4 5
}

code_name() {
  case "$1" in
    0) printf 'OK' ;;
    2) printf 'USAGE' ;;
    3) printf 'NO_INPUT' ;;
    4) printf 'NO_TOOL' ;;
    5) printf 'ASSERT_BROKEN' ;;
    *) printf 'UNKNOWN' ;;
  esac
}

classify() {
  # 「码 -> 类别」唯一映射：这是错误体系的锚，每个码只落一个类别。
  case "$1" in
    0) printf 'OK' ;;
    2) printf 'usage' ;;
    3 | 4) printf 'environment' ;;
    5) printf 'internal' ;;
    *) printf 'unknown' ;;
  esac
}

main() {
  local usage=0 environment=0 internal=0
  local code
  while IFS= read -r code; do
    printf 'code=%s name=%s category=%s\n' "$code" "$(code_name "$code")" "$(classify "$code")"
    case "$(classify "$code")" in
      usage) usage=$((usage + 1)) ;;
      environment) environment=$((environment + 1)) ;;
      internal) internal=$((internal + 1)) ;;
    esac
  done < <(probe_codes)
  printf 'taxonomy codes=5 usage=%d environment=%d internal=%d\n' \
    "$usage" "$environment" "$internal"
}

main "$@"
