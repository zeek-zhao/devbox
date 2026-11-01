#!/usr/bin/env bash
# ==================================================================
# 看板与仓库实况一致性校验
# ------------------------------------------------------------------
# 为什么需要它：docs/进度看板.html 是**手工维护**的静态快照，里面的
# 「608 个用例」「9 个已有毕业项目」全靠人同步。数字一旦落后于
# examples/ 与 project/ 的实况，它就是一份「看起来很权威的错文档」——
# 比没有看板更糟，因为读者不会怀疑它。
#
# 本脚本只比对两个最容易被引用错的数字：用例总数、毕业项目数。
# 层级分布、项目名这类描述性内容不在此列（无法机器判定对错）。
#
# 为什么放进 CI 而不是写在文档里提醒：提醒会被忽略，红灯不会。
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

board="docs/进度看板.html"
if [ ! -f "$board" ]; then
  echo "找不到看板：$board" >&2
  exit 1
fi

# 用例数：各轨道 examples/ 下的直接子目录（含 hello，与看板的计数口径一致）
cases=0
for dir in */examples; do
  [ -d "$dir" ] || continue
  n="$(find "$dir" -mindepth 1 -maxdepth 1 -type d -print | wc -l)"
  cases=$((cases + n))
done

# 毕业项目数：存在 project/ 目录的轨道数
projects=0
for dir in */project; do
  if [ -d "$dir" ]; then
    projects=$((projects + 1))
  fi
done

board_cases="$(grep -oE '[0-9]+ 个用例' "$board" 2>/dev/null | head -1 | grep -oE '[0-9]+' || true)"
board_projects="$(grep -oE '[0-9]+ 个已有毕业项目' "$board" 2>/dev/null | head -1 | grep -oE '[0-9]+' || true)"

fail=0
if [ -z "$board_cases" ]; then
  echo "FAIL: 看板里找不到「N 个用例」的表述，判据本身失效了" >&2
  fail=1
elif [ "$board_cases" != "$cases" ]; then
  echo "FAIL: 看板写 ${board_cases} 个用例，实际 ${cases} 个" >&2
  fail=1
fi

if [ -z "$board_projects" ]; then
  echo "FAIL: 看板里找不到「N 个已有毕业项目」的表述，判据本身失效了" >&2
  fail=1
elif [ "$board_projects" != "$projects" ]; then
  echo "FAIL: 看板写 ${board_projects} 个毕业项目，实际 ${projects} 个" >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "      改了 examples/ 或 project/ 之后，同步 $board 的 summary 一行" >&2
  exit 1
fi

echo "看板与实况一致：${cases} 个用例 / ${projects} 个毕业项目"
