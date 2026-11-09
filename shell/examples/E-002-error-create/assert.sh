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
grep -qF -e 'main.sh: validate-name: name is empty' <<<"$out" || {
  echo '[assert] 未命中标准化诊断行'
  fail=1
}
grep -qF -e 'rc=2' <<<"$out" || {
  echo '[assert] 未命中失败退出码行'
  fail=1
}
grep -qF -e 'rc=0' <<<"$out" || {
  echo '[assert] 未命中成功退出码行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
