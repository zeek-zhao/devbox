#!/usr/bin/env bash
# 计划与执行分离：--dry-run 只打印将要做的操作，不改文件系统。
set -euo pipefail

TARGET=""
DRY_RUN=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    *) TARGET="$1" ;;
  esac
  shift
done
[[ -n "$TARGET" ]]

plan() {
  printf 'would create %s\n' "$TARGET/app.conf"
  printf 'would create %s\n' "$TARGET/log/current"
}

if [[ -n "$DRY_RUN" ]]; then
  plan
  [[ ! -e "$TARGET" ]]
else
  mkdir -p "$TARGET/log"
  printf 'managed=ready\n' >"$TARGET/app.conf"
  : >"$TARGET/log/current"
  [[ -f "$TARGET/app.conf" ]]
fi
