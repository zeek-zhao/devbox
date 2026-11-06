#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^error_chain=load_settings: read_config: open failed$' <<<"$out" \
  || { echo "[assert] 未命中完整错误链行"; fail=1; }
grep -q '^root_code=3 depth=2$' <<<"$out" \
  || { echo "[assert] 未命中根因码保持行（码应在包装后仍为 3）"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
