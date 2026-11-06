#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")"

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^event code=3 op=load_user target=users.json user_id=42 request=GET /profile trace=t-42$' <<<"$out" \
  || { echo "[assert] 未命中 load_user 上下文行（层级上下文应逐层齐全）"; fail=1; }
grep -q '^event code=6 op=parse_profile target=body field=age value=abc$' <<<"$out" \
  || { echo "[assert] 未命中 parse_profile 字段行"; fail=1; }
n="$(grep -c '^event ' <<<"$out" || true)"
[ "$n" -eq 2 ] || { echo "[assert] event 行数期望 2，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
