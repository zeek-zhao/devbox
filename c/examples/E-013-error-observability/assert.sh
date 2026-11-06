#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")"

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^event seq=3 level=error op=disk-flush code=7 attempt=1$' <<<"$out" \
  || { echo "[assert] 未命中 IO 错误事件行"; fail=1; }
grep -q '^event seq=4 level=info op=http-get code=0 attempt=3$' <<<"$out" \
  || { echo "[assert] 未命中恢复成功事件行（attempt=3 应如实记录）"; fail=1; }
grep -q '^metrics total=4 timeouts=2 io_errors=1$' <<<"$out" \
  || { echo "[assert] 未命中计数器汇总行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
