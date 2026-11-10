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
grep -qF -e 'identity through chain: same=true' <<<"$out" || {
  echo '[assert] 未命中链上身份保持行'
  fail=1
}
grep -qF -e 'code survives chain: E_DB_DOWN' <<<"$out" || {
  echo '[assert] 未命中元数据存活行'
  fail=1
}
grep -qF -e 'identity after rewrap: same=false' <<<"$out" || {
  echo '[assert] 未命中重包装断身份行'
  fail=1
}
grep -qF -e 'instanceof after rewrap: false' <<<"$out" || {
  echo '[assert] 未命中重包装丢类型行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
