#!/usr/bin/env bash
# E-011 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^user view: payment PAY-1234 failed$' <<<"$out" \
  || { echo "[assert] 用户视图应只有稳定文案，不含内部细节"; fail=1; }
grep -q '^operator view: PaymentError { reference: "PAY-1234", source: ParseIntError { kind: InvalidDigit } }$' \
  <<<"$out" \
  || { echo "[assert] 排障视图应为完整 Debug 结构"; fail=1; }
grep -q '^root cause walk: invalid digit found in string$' <<<"$out" \
  || { echo "[assert] 未命中根因链输出"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
