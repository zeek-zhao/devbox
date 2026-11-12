#!/usr/bin/env bash
# ulimit 资源限制：-f 限制单文件大小，超限写入触发 SIGXFSZ 且文件被截断在限额处。
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-008-ulimit-resource-obs.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

nofile="$(ulimit -n)"
[[ "$nofile" =~ ^[0-9]+$ ]]
[[ "$nofile" -gt 0 ]]

rc=0
(
  ulimit -f 1
  head -c 5000 /dev/zero >"$WORK/big"
) 2>/dev/null || rc=$?
[[ "$rc" -eq 153 ]]

size="$(wc -c <"$WORK/big")"
[[ "$size" -le 1024 ]]
[[ "$size" -gt 0 ]]
printf 'ulimit=enforced sig=xfsz cap-bytes=%d\n' 1024
