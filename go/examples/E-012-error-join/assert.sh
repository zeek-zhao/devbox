#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'join: err=shard 1: disk unavailable' <<<"$out" \
  || { echo "[assert] 未命中聚合首行"; fail=1; }
grep -qF -e 'shard 3: auth rejected' <<<"$out" \
  || { echo "[assert] 未命中聚合次行"; fail=1; }
grep -qF -e 'join member disk: errors.Is(joined, ErrDisk)=true' <<<"$out" \
  || { echo "[assert] 未命中成员判定 disk 行"; fail=1; }
grep -qF -e 'join member auth: errors.Is(joined, ErrAuth)=true' <<<"$out" \
  || { echo "[assert] 未命中成员判定 auth 行"; fail=1; }
grep -qF -e 'join non-member: errors.Is(joined, other)=false' <<<"$out" \
  || { echo "[assert] 未命中非成员排他行"; fail=1; }
grep -qF -e 'join single: err=shard 7: disk unavailable' <<<"$out" \
  || { echo "[assert] 未命中单失败聚合行"; fail=1; }
grep -qF -e 'join empty: err==nil=true' <<<"$out" \
  || { echo "[assert] 未命中空聚合成 nil 行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
