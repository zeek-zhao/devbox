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
grep -qF -e 'item=gamma status=failed rc=2' <<<"$out" || {
  echo '[assert] 未命中 gamma 失败记录行'
  fail=1
}
grep -qF -e 'item=delta status=ok' <<<"$out" || {
  echo '[assert] 未命中 gamma 失败后继续执行的行'
  fail=1
}
grep -qF -e 'aggregate failed=2 passed=2' <<<"$out" || {
  echo '[assert] 未命中失败汇总行'
  fail=1
}
grep -qF -e 'failed list: beta(rc=3) gamma(rc=2)' <<<"$out" || {
  echo '[assert] 未命中失败清单行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
