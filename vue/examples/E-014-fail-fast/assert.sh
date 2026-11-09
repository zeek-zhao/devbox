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
grep -qF -e 'env missing: created=false code=E_ENV_REQUIRED field=DEVBOX_API_URL' <<<"$out" || {
  echo '[assert] 未命中前置拦截行'
  fail=1
}
grep -qF -e 'env ok: created=true' <<<"$out" || {
  echo '[assert] 未命中前置齐备行'
  fail=1
}
grep -qF -e 'fail-fast checks=2' <<<"$out" || {
  echo '[assert] 未命中校验项数行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
