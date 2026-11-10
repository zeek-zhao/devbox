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
grep -q '^count rows=5 amount_non_null=2$' <<<"$out" ||
  {
    echo "[assert] 未命中 COUNT(*)/COUNT(col) 对照行"
    fail=1
  }
grep -q '^south_sum_is_null=yes south_sum_coalesced=0$' <<<"$out" ||
  {
    echo "[assert] 未命中空集 SUM 为 NULL 行"
    fail=1
  }
grep -q '^eq_null_matches=0 is_null_matches=2$' <<<"$out" ||
  {
    echo "[assert] 未命中 = NULL 恒不匹配行"
    fail=1
  }
grep -q '^not_in_trap=0 not_in_fixed=3$' <<<"$out" ||
  {
    echo "[assert] 未命中 NOT IN 含 NULL 陷阱行"
    fail=1
  }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || {
  echo "ASSERT-FAIL"
  exit 1
}
