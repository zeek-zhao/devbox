#!/usr/bin/env bash
# E-015 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^join ok: Ok(Ok(42))$' <<<"$out" \
  || { echo "[assert] join 应收回 worker 的 Ok"; fail=1; }
grep -q '^join err propagated: BadInput(7)$' <<<"$out" \
  || { echo "[assert] join 应收回 worker 的 Err 并还原类型"; fail=1; }
grep -q '^channel: Ok(Err(BadInput(9)))$' <<<"$out" \
  || { echo "[assert] mpsc 应把错误作为值传出"; fail=1; }
grep -q '^poison recovered: counter 1 (increment before panic survived)$' \
  <<<"$out" \
  || { echo "[assert] 未命中锁中毒恢复取证"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
