#!/usr/bin/env bash
# 层配比可见性检查（#398 · M13-CONTENT-05，对应 D-9）
#
# 只做一件事：把 9 条学习轨的 L1–L4 用例目录数与 docs/10 §1 的区间判据对照，
# 输出一张对齐表。L0（环境自检）/ E（错误处理）/ T（排障演练）不计入。
#
# 判据（docs/10 §1 / docs/86 D-9）：
#   每轨知识点合计（L1+L2+L3+L4，不含 L0）应在 [70, 85]；
#   L4 为可选层——无 L4 的轨道要求 L2+L3 ≥ 15（深度由中间两层承接）。
#
# 输出：WARN 但不 FAIL——除非文件系统异常，本脚本永远 exit 0，
#       是否阻断由调用方决定（CI 侧是 continue-on-error 的 advisory job）。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

LOW=70
HIGH=85
DEEP_NO_L4=15

row() { printf '%-7s %4s %4s %4s %4s %6s %9s  %s\n' "$@"; }

row 轨道 L1 L2 L3 L4 合计 判据 状态
row ------ ---- ---- ---- ---- ------ ------- ------

total_all=0
warn=0
for lang in c cpp go java python rust shell vue db; do
  dir="$lang/examples"
  [ -d "$dir" ] || continue
  l1=0 l2=0 l3=0 l4=0
  for d in "$dir"/L1-*; do [ -d "$d" ] && l1=$((l1 + 1)); done
  for d in "$dir"/L2-*; do [ -d "$d" ] && l2=$((l2 + 1)); done
  for d in "$dir"/L3-*; do [ -d "$d" ] && l3=$((l3 + 1)); done
  for d in "$dir"/L4-*; do [ -d "$d" ] && l4=$((l4 + 1)); done
  sum=$((l1 + l2 + l3 + l4))
  total_all=$((total_all + sum))
  if [ "$sum" -lt "$LOW" ]; then
    status="WARN 低于下限（缺 $((LOW - sum)) 个）"
    warn=$((warn + 1))
  elif [ "$sum" -gt "$HIGH" ]; then
    status="WARN 高于上限（超 $((sum - HIGH)) 个）"
    warn=$((warn + 1))
  elif [ "$l4" -eq 0 ] && [ $((l2 + l3)) -lt "$DEEP_NO_L4" ]; then
    status="WARN 无 L4 且 L2+L3=$((l2 + l3)) < $DEEP_NO_L4"
    warn=$((warn + 1))
  elif [ "$l4" -eq 0 ]; then
    status="OK（无 L4，深度在 L2+L3=$((l2 + l3))）"
  else
    status="OK"
  fi
  row "$lang" "$l1" "$l2" "$l3" "$l4" "$sum" "[$LOW,$HIGH]" "$status"
done

printf '\n合计：9 轨 L1–L4 共 %d 个用例目录；区间判据 [%d,%d]；WARN %d 轨。\n' \
  "$total_all" "$LOW" "$HIGH" "$warn"
printf '说明：本检查为 advisory（WARN 不阻断），判据定义见 docs/10 §1 与 docs/86 D-9。\n'
exit 0
