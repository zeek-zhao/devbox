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
grep -qF -e 'load fast: result=data' <<<"$out" || {
  echo '[assert] 未命中按时完成行'
  fail=1
}
grep -qF -e 'load hung: result=E_TIMEOUT after 50ms' <<<"$out" || {
  echo '[assert] 未命中截止命中行'
  fail=1
}
grep -qF -e 'deadline conversions=1' <<<"$out" || {
  echo '[assert] 未命中截止生效结论行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
