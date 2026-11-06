#!/usr/bin/env bash
# E-003 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q 'expect-mode: fixture port 8080 (context attached)' <<<"$out" \
  || { echo "[assert] 未命中 expect 语境输出"; fail=1; }
grep -q 'handled-mode: invalid config -> fallback 0, exit stays 0' <<<"$out" \
  || { echo "[assert] 未命中 Result 回退输出"; fail=1; }
grep -q '^unwrap-mode: exit=101 (101 = panic)$' <<<"$out" \
  || { echo "[assert] unwrap 失败应体现为退出码 101"; fail=1; }
grep -q '^unwrap-mode: stderr-panicked=yes$' <<<"$out" \
  || { echo "[assert] 未命中 panic 消息取证"; fail=1; }
grep -q '^unwrap-mode: backtrace-hint=yes$' <<<"$out" \
  || { echo "[assert] 未命中 RUST_BACKTRACE 提示取证"; fail=1; }
grep -q '^unwrap-mode: context-in-message=no$' <<<"$out" \
  || { echo "[assert] unwrap 消息应无业务上下文"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
