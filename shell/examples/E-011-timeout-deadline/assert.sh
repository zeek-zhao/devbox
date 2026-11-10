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
grep -qF -e 'fast task: rc=0 kind=completed' <<<"$out" || {
  echo '[assert] 未命中按时完成任务行'
  fail=1
}
grep -qF -e 'hung task: rc=3 kind=timeout' <<<"$out" || {
  echo '[assert] 未命中截止时间命中行（124 -> 3）'
  fail=1
}
grep -qF -e 'deadline enforced: true' <<<"$out" || {
  echo '[assert] 未命中截止生效结论行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
