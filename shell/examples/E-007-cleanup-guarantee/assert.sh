#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
if [ "$rc" -ne 0 ]; then
  echo "[assert] run.sh 退出码非 0：rc=$rc"
  fail=1
fi
grep -qF -e 'right-mode: business exit preserved: 3' <<<"$out" || {
  echo '[assert] 未命中业务退出码保留行'
  fail=1
}
grep -qF -e 'wrong-mode: observed exit=1 (business 3 masked by cleanup)' <<<"$out" || {
  echo '[assert] 未命中清理顶替退出码行'
  fail=1
}
n="$(grep -c 'cleanup: scratch dir removed' <<<"$out" || true)"
if [ "$n" -lt 1 ]; then
  echo "[assert] 清理日志行期望至少 1 条，实际 $n"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
