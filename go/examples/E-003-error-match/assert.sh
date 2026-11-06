#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF 'match ==: wrapped == ErrNotFound: false' <<<"$out" \
  || { echo "[assert] 未命中 == 失配行"; fail=1; }
grep -qF 'match errors.Is(wrapped, ErrNotFound): true' <<<"$out" \
  || { echo "[assert] 未命中 errors.Is 命中行"; fail=1; }
grep -qF 'match errors.Is(wrapped, ErrQuota): false' <<<"$out" \
  || { echo "[assert] 未命中 errors.Is 排他行"; fail=1; }
grep -qF 'match custom Is: 45-day overdue matches policy(30+): true' <<<"$out" \
  || { echo "[assert] 未命中自定义 Is 命中行"; fail=1; }
grep -qF 'match custom Is: 5-day overdue matches policy(30+): false' <<<"$out" \
  || { echo "[assert] 未命中自定义 Is 排他行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
