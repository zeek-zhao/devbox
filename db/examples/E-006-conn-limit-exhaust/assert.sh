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
grep -q '^lease_exceeded err=1226 class=capacity action=shed$' <<<"$out" ||
  {
    echo "[assert] 未命中 1226 容量归因行"
    fail=1
  }
grep -q '^release conn=1 freed=yes$' <<<"$out" ||
  {
    echo "[assert] 未命中释放租约行"
    fail=1
  }
grep -q '^retry lease ok=yes$' <<<"$out" ||
  {
    echo "[assert] 未命中让路后重试成功行"
    fail=1
  }
grep -q '^log_rows=2$' <<<"$out" ||
  {
    echo "[assert] 未命中日志行数（应含初始 1 行 + 重试 1 行）"
    fail=1
  }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || {
  echo "ASSERT-FAIL"
  exit 1
}
