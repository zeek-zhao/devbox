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
n="$(grep -c 'code=7 message=missing-config' <<<"$out" || true)"
if [ "$n" -ne 3 ]; then
  echo "[assert] 三层透传身份行期望 3 条，实际 $n"
  fail=1
fi
grep -qF -e 'layer=swallowed code=0 message=missing-config' <<<"$out" || {
  echo '[assert] 未命中吞错断身份行'
  fail=1
}
grep -qF -e 'transparent chain: identity preserved' <<<"$out" || {
  echo '[assert] 未命中透传结论行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
