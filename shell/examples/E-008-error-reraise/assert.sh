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
grep -qF -e 'mode=swallow report=step failed rc=4 exit=0' <<<"$out" || {
  echo '[assert] 未命中吞错对照行'
  fail=1
}
grep -qF -e 'mode=reraise report=step failed rc=4 exit=4' <<<"$out" || {
  echo '[assert] 未命中重抛行'
  fail=1
}
grep -qF -e 'step: quota exceeded' <<<"$out" || {
  echo '[assert] 未命中底层失败诊断行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
