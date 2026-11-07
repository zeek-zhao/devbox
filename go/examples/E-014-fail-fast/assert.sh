#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'fail-fast normal: n=16 err=<nil>' <<<"$out" \
  || { echo "[assert] 未命中正常输入行"; fail=1; }
grep -qF -e 'fail-fast recovered: n=0 err=parse roman "xyz": symbol table missing "x": programmer bug: invariant violated' <<<"$out" \
  || { echo "[assert] 未命中 panic 转 error 行"; fail=1; }
grep -qF -e 'fail-fast policy: unrecoverable -> exit(70) (simulated)' <<<"$out" \
  || { echo "[assert] 未命中快速失败策略行"; fail=1; }
grep -qF -e 'fail-fast boundary: panic converted, errors.Is(err, ErrInvariant)=true' <<<"$out" \
  || { echo "[assert] 未命中边界转换判定行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
