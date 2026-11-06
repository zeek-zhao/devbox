#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^\[bad \] value=0 error_reported=0 (失败被吞，拿到假数据)$' <<<"$out" \
  || { echo "[assert] 未命中坏版本吞错行"; fail=1; }
grep -q '^\[bad \] downstream computed=0 (假数据流进下游)$' <<<"$out" \
  || { echo "[assert] 未命中坏版本下游污染行"; fail=1; }
grep -q '^\[good\] value=none error_reported=1 code=3 (失败显式暴露)$' <<<"$out" \
  || { echo "[assert] 未命中好版本报错行"; fail=1; }
grep -q '^\[good\] downstream aborted=1 (下游被保护，未拿到假数据)$' <<<"$out" \
  || { echo "[assert] 未命中好版本下游保护行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
