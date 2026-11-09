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
grep -qF -e 'matched=E_NETWORK action=retry' <<<"$out" || {
  echo '[assert] 未命中网络错误重试分支'
  fail=1
}
grep -qF -e 'matched=plain-error action=report' <<<"$out" || {
  echo '[assert] 未命中未知错误上报分支'
  fail=1
}
n="$(grep -c '^matched=' <<<"$out" || true)"
if [ "$n" -ne 4 ]; then
  echo "[assert] matched= 行数期望 4，实际 $n"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
