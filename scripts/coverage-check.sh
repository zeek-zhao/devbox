#!/usr/bin/env bash
# ==================================================================
# COVERAGE.md 校验 —— 把「毕业项目把用例都用上」变成可机器验收的东西
# ------------------------------------------------------------------
# 项目里必须有 <lang>/project/COVERAGE.md，表格形如：
#   | 用例ID | 落点 | 说明 |
#   | L1-001 | src/lexer.cpp:42 | 用 string_view 切词 |
#
# 校验四件事（缺一条，这张表就只是自说自话）：
#   1) 表里声明的 ID 在 examples/ 下真实存在（不许凭空写）
#   2) 表里声明的 ID 在 project/ 的代码里确实出现过（注释里写 ID 也算，便于追溯）
#   3) examples/ 下的每个 ID 都在表里声明过（不许漏）
#   4) 表本身不是空的
#
# 第 3 条是「反向测试」的落点：故意从表里删一行，本脚本必须变红。
# 少了第 3 条，删行也能过，覆盖校验就退化成了摆设。
#
# 不用临时文件：本机的 rm 包装器对 /tmp 路径会拦，脚本中途退出会看不清是哪条错。
#
# 阶段 0 只有 hello 一个用例，此时表里应当只有 hello 一行。
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LANGS="${1:-cpp go rust shell python java}"
failed=0

# 从覆盖表取第 1 列，并严格约束形态：只认「字母开头」的 ID。
# 否则 markdown 分隔行 |---| 会被当成 ID "---"，报成不存在的用例。
cov_ids() {
  local cov="$1"
  grep -E '^\|' "$cov" \
    | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}' \
    | grep -E '^[A-Za-z][A-Za-z0-9_.-]*$' || true
}

check_lang() {
  local lang="$1"
  local cov="$lang/project/COVERAGE.md"
  local ex_dir="$lang/examples"
  local bad=0

  if [ ! -d "$ex_dir" ]; then
    echo "[skip] $lang: 没有 examples 目录"
    return 0
  fi

  local total
  total=$(find "$ex_dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  if [ "$total" -eq 0 ]; then
    echo "[skip] $lang: examples 为空"
    return 0
  fi

  if [ ! -f "$cov" ]; then
    echo "[FAIL] $lang: 缺 $cov（$total 个用例没有任何覆盖声明）"
    failed=$((failed + 1))
    return 0
  fi

  echo "==> 校验 $lang（$total 个用例）"

  local declared
  declared="$(cov_ids "$cov" | sort -u)"

  # 4) 表不能是空的
  if [ -z "$declared" ]; then
    echo "  [FAIL] $cov 里没有任何用例 ID"
    bad=$((bad + 1))
  fi

  # 1) 声明了不存在的用例
  local id
  for id in $declared; do
    if [ ! -d "$ex_dir/$id" ]; then
      echo "  [FAIL] 声明了不存在的用例: $id"
      bad=$((bad + 1))
    fi
  done

  # 2) 每个用例 ID 必须在 project/ 的代码里出现
  #    排除 COVERAGE.md 自身：否则表格里写一行就"自证"了，等于没校验
  local covered=0 missing=0 dir
  while IFS= read -r dir; do
    id="$(basename "$dir")"
    if grep -rqF -- "$id" "$lang/project" --exclude='COVERAGE.md' 2>/dev/null; then
      covered=$((covered + 1))
    else
      echo "  [FAIL] 用例 $id 在 $lang/project/ 里找不到引用"
      missing=$((missing + 1))
    fi
  done < <(find "$ex_dir" -mindepth 1 -maxdepth 1 -type d)
  [ "$missing" -gt 0 ] && bad=$((bad + 1))

  # 3) 反向：examples 下的每个 ID 必须都在表里声明过
  local undeclared=0
  while IFS= read -r dir; do
    id="$(basename "$dir")"
    if ! printf '%s\n' "$declared" | grep -qxF -- "$id"; then
      echo "  [FAIL] 用例 $id 没有在 $cov 的表格里声明"
      undeclared=$((undeclared + 1))
    fi
  done < <(find "$ex_dir" -mindepth 1 -maxdepth 1 -type d)
  [ "$undeclared" -gt 0 ] && bad=$((bad + 1))

  local ndecl=0
  [ -n "$declared" ] && ndecl=$(printf '%s\n' "$declared" | grep -c '' || true)
  echo "  覆盖 $covered / $total（声明 $ndecl 条）"
  [ "$bad" -gt 0 ] && failed=$((failed + 1))
  return 0
}

for l in $LANGS; do
  if [ -d "$l" ]; then
    check_lang "$l" || true
  fi
done

echo "------------------------------------------------------------------"
if [ "$failed" -ne 0 ]; then
  echo "COVERAGE 校验失败（$failed 个语言不过）" >&2
  exit 1
fi
echo "COVERAGE 校验通过"
