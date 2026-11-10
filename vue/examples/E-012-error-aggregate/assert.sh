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
grep -qF -e 'source=a status=fulfilled value=payload-a' <<<"$out" || {
  echo '[assert] 未命中成功源行（失败未遮蔽成功）'
  fail=1
}
grep -qF -e 'source=c status=rejected reason=E_QUOTA' <<<"$out" || {
  echo '[assert] 未命中第二个失败源行（失败未互相遮蔽）'
  fail=1
}
grep -qF -e 'aggregate ok=1 failed=2' <<<"$out" || {
  echo '[assert] 未命中聚合汇总行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
