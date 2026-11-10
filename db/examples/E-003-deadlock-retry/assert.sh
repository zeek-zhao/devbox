#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^deadlock err=1213 victim=b retryable=yes$' <<<"$out" \
  || { echo "[assert] 未命中死锁归因行"; fail=1; }
grep -q '^retry attempt=2 ok=yes$' <<<"$out" \
  || { echo "[assert] 未命中重试成功行"; fail=1; }
grep -q '^final id=1 balance=85$' <<<"$out" \
  || { echo "[assert] 未命中最终余额行 id=1"; fail=1; }
grep -q '^final id=2 balance=70$' <<<"$out" \
  || { echo "[assert] 未命中最终余额行 id=2"; fail=1; }
grep -c '^final id=' <<<"$out" | grep -qx '3' \
  || { echo "[assert] final id= 行数期望 3"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
