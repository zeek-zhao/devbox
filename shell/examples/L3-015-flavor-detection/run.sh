#!/usr/bin/env bash
# 跨平台 flavor 检测：先探测工具链口味（GNU/busybox），再断言本镜像的可移植写法。
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-015-flavor-detection.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

detect_flavor() {
  if date --version >/dev/null 2>&1; then
    echo gnu
  elif date 2>&1 | grep -q BusyBox; then
    echo busybox
  else
    echo unknown
  fi
}

flavor="$(detect_flavor)"
[[ "$flavor" == gnu ]]

resolved="$(readlink -f /bin)"
[[ -d "$resolved" ]]

printf 'before\n' >"$WORK/f.txt"
sed -i 's/before/after/' "$WORK/f.txt"
[[ "$(cat "$WORK/f.txt")" == after ]]
printf 'flavor=%s readlink-f=ok sed-i=ok\n' "$flavor"
