#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q 'app_code=2 errno=34' <<<"$out" \
  || { echo "[assert] 未命中 ERANGE(34) -> OUT_OF_RANGE(2) 转换行"; fail=1; }
grep -q 'input=12abc *app_code=1 errno=0 value=12$' <<<"$out" \
  || { echo "[assert] 未命中尾随垃圾 -> BAD_INPUT 行"; fail=1; }
grep -q '^map ENOENT=2 -> app_code=3$' <<<"$out" \
  || { echo "[assert] 未命中 ENOENT 映射行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
