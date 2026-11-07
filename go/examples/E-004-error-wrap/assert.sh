#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF 'wrapped text: commit log: write segment: disk full' <<<"$out" \
  || { echo "[assert] 未命中三层包装诊断行"; fail=1; }
grep -qF 'unwrap once: write segment: disk full' <<<"$out" \
  || { echo "[assert] 未命中 Unwrap 剥层行"; fail=1; }
grep -qF 'wrap %w keeps chain: errors.Is(err, ErrDiskFull)=true' <<<"$out" \
  || { echo "[assert] 未命中 %w 保链行"; fail=1; }
grep -qF 'wrap %v loses chain: errors.Is(err, ErrDiskFull)=false unwrap=nil: true' <<<"$out" \
  || { echo "[assert] 未命中 %v 断链对照行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
