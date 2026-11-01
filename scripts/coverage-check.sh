#!/usr/bin/env bash
# ==================================================================
# COVERAGE.md 校验 —— 把「毕业项目把用例都用上」变成可机器验收的东西
# ------------------------------------------------------------------
# 项目里必须有 <lang>/project/COVERAGE.md，表格形如：
#   | 用例ID | 落点 | 说明 |
#   | L1-001-references-pointers | src/lexer.cpp:42 | 用 string_view 切词 |
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
# ---- pending 语义（阶段 2 引入，见 devbox-里程碑与人工检验.md §M2）----
# 阶段 2 要铺 53 个用例，但项目骨架只真实用到了 hello 一个。若强行要求 53 个用例
# 都在 project/ 里有「代码引用」，那些引用只能是空注释，本校验立刻退化成自证。
# 所以用例可以在自己的 README.md 里显式声明：
#
#     coverage: pending        # 用例已落地，但项目尚未引用
#
# pending 的用例对第 2、3 条豁免，但会被单独统计并打印 —— 它不是「通过」，
# 而是「明账上的欠债」。阶段 4 收口时用 --strict 跑，pending 一律算失败。
#
# 用法：
#   bash scripts/coverage-check.sh                 # 全语言，非严格
#   bash scripts/coverage-check.sh cpp             # 只查一门
#   bash scripts/coverage-check.sh --strict        # pending 也算失败（阶段 4 用）
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STRICT=0
LANGS=""
for a in "$@"; do
  case "$a" in
    --strict) STRICT=1 ;;
    -*) echo "未知选项: $a" >&2; exit 2 ;;
    *) LANGS="${LANGS:+$LANGS }$a" ;;
  esac
done
[ -n "$LANGS" ] || LANGS="c cpp go rust shell python java vue"

failed=0
pending_total=0

# 从覆盖表取第 1 列，并严格约束形态：只认「字母开头」的 ID。
# 否则 markdown 分隔行 |---| 会被当成 ID "---"，报成不存在的用例。
cov_ids() {
  local cov="$1"
  grep -E '^\|' "$cov" \
    | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}' \
    | grep -E '^[A-Za-z][A-Za-z0-9_.-]*$' || true
}

# 用例是否声明了 pending：看它自己的 README.md，不看别处。
# 允许被 HTML 注释包起来（<!-- coverage: pending -->），方便写在文档顶部而不渲染出来。
is_pending() {
  local dir="$1"
  [ -f "$dir/README.md" ] || return 1
  grep -qE '^[[:space:]]*(<!--[[:space:]]*)?coverage:[[:space:]]*pending' "$dir/README.md"
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

  # 先按 pending 与否分成两拨：pending 只统计，不参与第 2、3 条
  local pend_list="" live_list="" dir id
  while IFS= read -r dir; do
    id="$(basename "$dir")"
    if is_pending "$dir"; then
      pend_list="${pend_list}${id}"$'\n'
    else
      live_list="${live_list}${id}"$'\n'
    fi
  done < <(find "$ex_dir" -mindepth 1 -maxdepth 1 -type d | sort)

  local npend=0 nlive=0
  [ -n "$pend_list" ] && npend=$(printf '%s' "$pend_list" | grep -c '' || true)
  [ -n "$live_list" ] && nlive=$(printf '%s' "$live_list" | grep -c '' || true)

  if [ ! -f "$cov" ]; then
    if [ "$nlive" -eq 0 ]; then
      echo "[skip] $lang: $total 个用例全部 pending，无覆盖声明需求"
      echo "  pending $npend 个"
      pending_total=$((pending_total + npend))
      return 0
    fi
    echo "[FAIL] $lang: 缺 $cov（$nlive 个非 pending 用例没有任何覆盖声明）"
    failed=$((failed + 1))
    pending_total=$((pending_total + npend))
    return 0
  fi

  echo "==> 校验 $lang（$total 个用例，其中 pending $npend）"

  local declared
  declared="$(cov_ids "$cov" | sort -u)"

  # 4) 表不能是空的 —— 只有存在非 pending 用例时才要求
  if [ -z "$declared" ] && [ "$nlive" -gt 0 ]; then
    echo "  [FAIL] $cov 里没有任何用例 ID"
    bad=$((bad + 1))
  fi

  # 1) 声明了不存在的用例（pending 与否都要查，这是防凭空写）
  for id in $declared; do
    if [ ! -d "$ex_dir/$id" ]; then
      echo "  [FAIL] 声明了不存在的用例: $id"
      bad=$((bad + 1))
    fi
  done

  # 2) 每个非 pending 用例 ID 必须在 project/ 的代码里出现
  #    排除 COVERAGE.md 自身：否则表格里写一行就"自证"了，等于没校验
  local covered=0 missing=0
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    # 注意：--exclude 必须放在 `--` 之前。放在 `--` 之后会被当成文件名，
    # 排除静默失效 —— 那样只要把 ID 写进 COVERAGE.md 表格就自证了。
    if grep -rqF --exclude='COVERAGE.md' -- "$id" "$lang/project" 2>/dev/null; then
      covered=$((covered + 1))
    else
      echo "  [FAIL] 用例 $id 在 $lang/project/ 里找不到引用（若尚未接入请标 coverage: pending）"
      missing=$((missing + 1))
    fi
  done <<< "$live_list"
  [ "$missing" -gt 0 ] && bad=$((bad + 1))

  # 3) 反向：每个非 pending 用例必须都在表里声明过
  local undeclared=0
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    if ! printf '%s\n' "$declared" | grep -qxF -- "$id"; then
      echo "  [FAIL] 用例 $id 没有在 $cov 的表格里声明"
      undeclared=$((undeclared + 1))
    fi
  done <<< "$live_list"
  [ "$undeclared" -gt 0 ] && bad=$((bad + 1))

  local ndecl=0
  [ -n "$declared" ] && ndecl=$(printf '%s\n' "$declared" | grep -c '' || true)
  echo "  覆盖 $covered / $nlive（声明 $ndecl 条）"
  if [ "$npend" -gt 0 ]; then
    echo "  pending $npend 个（未接入 project，非严格模式下豁免）"
    pending_total=$((pending_total + npend))
  fi
  [ "$bad" -gt 0 ] && failed=$((failed + 1))
  return 0
}

for l in $LANGS; do
  if [ -d "$l" ]; then
    check_lang "$l" || true
  fi
done

echo "------------------------------------------------------------------"
if [ "$STRICT" -eq 1 ] && [ "$pending_total" -gt 0 ]; then
  echo "STRICT：仍有 $pending_total 个 pending 用例未登记覆盖（阶段 4 收口前必须清零）" >&2
  failed=$((failed + 1))
fi
if [ "$failed" -ne 0 ]; then
  echo "COVERAGE 校验失败（$failed 个语言不过）" >&2
  exit 1
fi
if [ "$pending_total" -gt 0 ]; then
  echo "COVERAGE 校验通过（pending $pending_total 个，--strict 下会失败）"
else
  echo "COVERAGE 校验通过"
fi
