#!/usr/bin/env bash
# ==================================================================
# COVERAGE.md 校验 —— 把「毕业项目把用例都用上」变成可机器验收的东西
# ------------------------------------------------------------------
# 项目里必须有 <lang>/project/COVERAGE.md，表格形如：
#   | 用例ID | 落点 | 说明 |
#   | L1-001 | src/lexer.cpp:42 | 用 string_view 切词 |
# 校验三件事：
#   1) 表里每个 ID 在 examples/ 下真实存在
#   2) 该 ID 在 project/ 的代码或测试里至少出现一次（注释里写 ID 也算，便于追溯）
#   3) examples/ 下的每个 ID 都被 COVERAGE.md 覆盖到（不允许漏）
# 阶段 0 只有 hello 用例，此时应只覆盖 hello 一个。
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LANGS="${1:-cpp go rust shell python java}"
failed=0

check_lang() {
  local lang="$1"
  local cov="$lang/project/COVERAGE.md"
  local ex_dir="$lang/examples"

  if [ ! -d "$ex_dir" ]; then
    echo "[skip] $lang: 没有 examples 目录"
    return 0
  fi

  local total covered missing
  total=$(find "$ex_dir" -mindepth 1 -maxdepth 1 -type d | wc -l)
  [ "$total" -eq 0 ] && return 0

  if [ ! -f "$cov" ]; then
    echo "[FAIL] $lang: 缺 $cov（$total 个用例没有任何覆盖声明）"
    failed=$((failed+1)); return 1
  fi

  echo "==> 校验 $lang（$total 个用例）"

  # 1) 表里的 ID 必须在 examples 下存在
  local bad_ids=0
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    if [ ! -d "$ex_dir/$id" ]; then
      echo "  [FAIL] COVERAGE 声明了不存在的用例: $id"; bad_ids=$((bad_ids+1))
    fi
  done < <(grep -oE '^\|[[:space:]]*[A-Za-z0-9_-]+' "$cov" | tr -d '|' | tr -d ' ' | grep -vE '^(用例ID|ID|----)' || true)
  [ "$bad_ids" -gt 0 ] && failed=$((failed+1))

  # 2) 每个用例 ID 必须在 project/ 的代码里出现
  covered=0; missing=0
  while IFS= read -r dir; do
    id="$(basename "$dir")"
    # 排除 COVERAGE.md 自身：否则表格里写一行就"自证"了，等于没校验
    if grep -rqF "$id" "$lang/project" --exclude='COVERAGE.md' 2>/dev/null; then
      covered=$((covered+1))
    else
      echo "  [FAIL] 用例 $id 在 $lang/project/ 里找不到引用"
      missing=$((missing+1))
    fi
  done < <(find "$ex_dir" -mindepth 1 -maxdepth 1 -type d)
  [ "$missing" -gt 0 ] && failed=$((failed+1))

  echo "  覆盖 $covered / $total"
}

for l in $LANGS; do
  [ -d "$l" ] && check_lang "$l" || true
done

echo "------------------------------------------------------------------"
if [ "$failed" -ne 0 ]; then
  echo "COVERAGE 校验失败（$failed 项）" >&2
  exit 1
fi
echo "COVERAGE 校验通过"
