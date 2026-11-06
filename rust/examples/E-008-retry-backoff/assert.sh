#!/usr/bin/env bash
# E-008 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^retry: recovered after transient errors, value payload$' <<<"$out" \
  || { echo "[assert] 瞬时错误应在退避后恢复"; fail=1; }
grep -q '^broken: no retry on permanent error (schema mismatch)$' <<<"$out" \
  || { echo "[assert] 永久错误应立即上抛不重试"; fail=1; }
grep -q '^policy: retry transient with exponential backoff, fail fast on permanent$' \
  <<<"$out" \
  || { echo "[assert] 未命中重试策略结论行"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
