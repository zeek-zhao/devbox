#!/usr/bin/env bash
# 毕业项目统一验证汇总（#394 · M13-CONTENT-01）
#
# 逐轨调用 <lang>/project/verify.sh，统计「可运行率」= 判定全过的轨数 / 总轨数。
# 用法：bash scripts/verify-projects.sh [--host]
#   --host  传给各轨 verify.sh，强制在宿主环境跑（默认优先本轨镜像）
# 输出：每轨一行 <lang> <pass>/<total> <rc>，末行 `<通过轨数>/<总轨数> 项目可运行`。
# 退出码：全部通过 0；有轨失败 1。
# 注意：db 轨需要先 db/scripts/up.sh && db/scripts/wait-ready.sh。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

LANGS="c cpp go java python rust shell vue db"
ok=0
total=0
failed=""
for lang in $LANGS; do
  verify="$lang/project/verify.sh"
  total=$((total + 1))
  if [ ! -f "$verify" ]; then
    printf '%-7s %-8s %s\n' "$lang" "MISSING" "无 project/verify.sh"
    failed="$failed $lang"
    continue
  fi
  log="$(mktemp)"
  bash "$verify" "$@" >"$log" 2>&1
  rc=$?
  summary="$(grep -aE '^[0-9]+/[0-9]+ 判定符合预期$' "$log" | tail -1)"
  [ -z "$summary" ] && summary="$(tail -1 "$log")"
  if [ "$rc" -eq 0 ]; then
    ok=$((ok + 1))
    printf '%-7s %-8s rc=0\n' "$lang" "${summary%% *}"
  else
    printf '%-7s %-8s rc=%d\n' "$lang" "${summary%% *}" "$rc"
    failed="$failed $lang"
    sed -n 's/^\[fail\] /         - /p' "$log" | head -5
  fi
  rm -f "$log"
done

printf '\n%d/%d 项目可运行\n' "$ok" "$total"
[ "$ok" -eq "$total" ] || {
  printf '未通过轨：%s\n' "$(echo "$failed" | sed 's/^ //')"
  exit 1
}
