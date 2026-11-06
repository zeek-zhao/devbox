#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")"

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
# bad 路径：closed 必须出现在 caught 之前（异常先展开、守卫先关闭）
awk '/processing \/tmp\/devbox-e009-bad.txt/{p=1} p && /^closed$/{c=NR} /bad path: caught bad header/{b=NR} END{exit !(c>0 && b>0 && c<b)}' <<<"$out" \
  || { echo "[assert] 异常路径未先关闭再捕获（泄漏或顺序错）"; fail=1; }
# 三条路径各关闭/失败恰一次：closed 总数应为 2（good 正常 + bad 异常）
closes=$(grep -c '^closed$' <<<"$out")
[ "$closes" -eq 2 ] || { echo "[assert] closed 次数=$closes，应为 2（不多关、不漏关）"; fail=1; }
grep -q 'missing path: caught cannot open' <<<"$out" || { echo "[assert] 未命中打不开文件诊断行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
