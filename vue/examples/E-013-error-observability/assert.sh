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
grep -qF -e 'report component=Card message=boom info=render function' <<<"$out" || {
  echo '[assert] 未命中 Card 渲染错误上报行'
  fail=1
}
grep -qF -e 'report component=Page message=async blew info=setup function' <<<"$out" || {
  echo '[assert] 未命中 Page 异步错误上报行'
  fail=1
}
grep -qF -e 'reports=2 fields=3 (component, message, info)' <<<"$out" || {
  echo '[assert] 未命中上报汇总行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
