#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
# 失败路径：没拿到锁，不得释放锁；已持有的 handle/buf 必须按逆序释放
grep -q '^-- failure path --$' <<<"$out" || { echo "[assert] 未命中失败路径标记"; fail=1; }
grep -q '^open_session rc=8$' <<<"$out" || { echo "[assert] 未命中失败路径返回码行"; fail=1; }
awk '/^-- failure path --/{f=1} f' <<<"$out" | grep -q '^release lock$' \
  && { echo "[assert] 失败路径不应释放未持有的锁"; fail=1; }
awk '/^-- failure path --/{f=1} f' <<<"$out" | grep -q '^release handle$' \
  || { echo "[assert] 失败路径未释放已持有的 handle"; fail=1; }
awk '/^-- failure path --/{f=1} f' <<<"$out" | grep -q '^release buf$' \
  || { echo "[assert] 失败路径未释放已持有的 buf"; fail=1; }
# 成功路径：三个资源全部释放
grep -q '^open_session rc=0$' <<<"$out" || { echo "[assert] 未命中成功路径返回码行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
