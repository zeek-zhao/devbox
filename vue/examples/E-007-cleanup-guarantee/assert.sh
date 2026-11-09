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
grep -qF -e 'runs=2 cleanups=1 (invalidation cleanup ran)' <<<"$out" || {
  echo '[assert] 未命中失效路径清理行'
  fail=1
}
grep -qF -e 'scope stopped: runs=2 cleanups=2' <<<"$out" || {
  echo '[assert] 未命中停止路径清理行'
  fail=1
}
grep -qF -e 'cleanup on stop: true' <<<"$out" || {
  echo '[assert] 未命中清理结论行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
