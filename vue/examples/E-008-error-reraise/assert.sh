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
grep -qF -e 'mode=swallow: parent-saw=true app-reports=0' <<<"$out" || {
  echo '[assert] 未命中吞掉对照行'
  fail=1
}
grep -qF -e 'mode=passthrough: parent-saw=true app-reports=1 first=leaf boom' <<<"$out" || {
  echo '[assert] 未命中放行对照行'
  fail=1
}
grep -qF -e 'mode=reraise: parent-saw=true app-reports=2 first=wrapped: leaf boom' <<<"$out" || {
  echo '[assert] 未命中重抛对照行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
