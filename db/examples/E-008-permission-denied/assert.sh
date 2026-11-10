#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || {
  echo "[assert] run.sh 退出码非 0：rc=$rc"
  fail=1
}
grep -q '^insert_denied err=1142 class=permission retryable=no$' <<<"$out" ||
  {
    echo "[assert] 未命中 1142 表级拒绝行"
    fail=1
  }
grep -q '^grant_fixed insert_ok=1$' <<<"$out" ||
  {
    echo "[assert] 未命中 GRANT 修复行"
    fail=1
  }
grep -q '^revoked err=1142 closed=yes$' <<<"$out" ||
  {
    echo "[assert] 未命中 REVOKE 生效行"
    fail=1
  }
grep -q '^no_db_access err=1044 class=permission retryable=no$' <<<"$out" ||
  {
    echo "[assert] 未命中 1044 连库拒绝行"
    fail=1
  }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || {
  echo "ASSERT-FAIL"
  exit 1
}
