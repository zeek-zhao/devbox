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
# ---- 用例的两种「豁免」声明（写在自己的 README.md 里，可以用 HTML 注释包起来）----
#
#   coverage: pending          # 用例已落地，项目尚未引用（阶段 4 收口前必须清零）
#   coverage: exempt <原因>    # 用例与项目形态天然无关，永久不接入（原因必填）
#
# pending 与 exempt 都对第 2、3 条豁免，但两者性质不同：
#
#   pending = 明账上的**欠债**。阶段 4 用 --strict 跑，pending 一律算失败。
#   exempt  = 明账上的**决定**。--strict 下也不算失败，但必须打印原因统计，
#             且原因不能为空 —— 空原因等于没写，下次没人知道当初为什么豁免。
#
# 为什么要有 exempt：
#   不是每个用例都能落进毕业项目。比如「用 jq 解析 JSON」这种单点工具用例，
#   硬塞进一个 HTTP 服务项目里只能变成一行空注释，反而让覆盖表退化成自证。
#   与其逼人写假引用，不如让它显式声明「这条我不用，因为 X」——
#   这样「有多少条是有意不接的」变成可数的数字，而不是靠人记。
#
# 用法：
#   bash scripts/coverage-check.sh                 # 全轨道，非严格
#   bash scripts/coverage-check.sh cpp             # 只查一门
#   bash scripts/coverage-check.sh --strict        # pending 也算失败（阶段 4 用）
#
# 退出码：0 通过 / 1 校验失败 / 2 参数或环境问题（不许当成通过）
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

# 不给参数就自动发现：凡是有 examples/ 的顶层目录都算一门轨道。
# 原来是写死的 c cpp go rust shell python java vue —— 结果 db 轨道
# 有 77 个用例和一张 COVERAGE.md，却从来没被校验过。
# 写死名单的坑是「加了新轨道，忘了加进名单」，而那种漏是静默的。
if [ -z "$LANGS" ]; then
  for d in */; do
    d="${d%/}"
    [ -d "$d/examples" ] && LANGS="${LANGS:+$LANGS }$d"
  done
fi

if [ -z "$LANGS" ]; then
  echo "ERROR: 一个带 examples/ 的轨道都没找到，检查工作目录" >&2
  exit 2
fi

# 显式指定的轨道名必须真实存在。
# 原来 `if [ -d "$l" ]` 直接把不存在的名字跳过 ——
# `bash scripts/coverage-check.sh nosuchlang` 返回 0，看起来像「校验通过」。
for l in $LANGS; do
  if [ ! -d "$l" ]; then
    echo "ERROR: 轨道 '$l' 不存在（没有 $l/ 目录）" >&2
    avail=""
    for d in */; do d="${d%/}"; [ -d "$d/examples" ] && avail="$avail $d"; done
    echo "       可用轨道：${avail# }" >&2
    exit 2
  fi
done

failed=0
pending_total=0
exempt_total=0
pending_detail=""
exempt_detail=""

# 从覆盖表取第 1 列，并严格约束形态：只认「字母开头」的 ID。
# 否则 markdown 分隔行 |---| 会被当成 ID "---"，报成不存在的用例。
cov_ids() {
  local cov="$1"
  grep -E '^\|' "$cov" \
    | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}' \
    | grep -E '^[A-Za-z][A-Za-z0-9_.-]*$' || true
}

# 读用例自己的 README.md，输出 "<状态>|<原因>"，状态是 pending 或 exempt。
# 必须锚定行首（允许前置 HTML 注释），否则文档里举例说明「你可以写
# coverage: exempt ...」也会被当成声明。
# 注意分隔符用 #：模式里要用 \| 做交替，用 | 当分隔符会打架。
cov_state() {
  local dir="$1" line
  [ -f "$dir/README.md" ] || return 0
  line="$(sed -n 's#^[[:space:]]*\(<!--[[:space:]]*\)\{0,1\}coverage:[[:space:]]*\(pending\|exempt\)\(.*\)$#\2|\3#p' "$dir/README.md" | head -1)"
  [ -n "$line" ] || return 0
  local kind="${line%%|*}"
  local reason="${line#*|}"
  reason="${reason%%-->*}"                       # 去掉 HTML 注释尾巴
  reason="$(printf '%s' "$reason" | sed -E 's/^[[:space:]]*#?[[:space:]]*//; s/[[:space:]]+$//')"
  printf '%s|%s\n' "$kind" "$reason"
}

check_lang() {
  local lang="$1"
  local cov="$lang/project/COVERAGE.md"
  local ex_dir="$lang/examples"
  local bad=0

  local total
  total=$(find "$ex_dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  if [ "$total" -eq 0 ]; then
    echo "[skip] $lang: examples 为空"
    return 0
  fi

  # 按声明分成三拨：exempt / pending 只统计，不参与第 2、3 条
  local pend_list="" live_list="" exempt_list="" dir id state kind reason
  local no_reason=""
  while IFS= read -r dir; do
    id="$(basename "$dir")"
    state="$(cov_state "$dir")"
    kind="${state%%|*}"
    reason=""
    [ -n "$state" ] && reason="${state#*|}"
    case "$kind" in
      exempt)
        # 空原因不在这里报 —— 先攒着，等打印完轨道标题再报，否则这行会跑到标题上面
        [ -n "$reason" ] || no_reason="${no_reason}${id} "
        exempt_list="${exempt_list}${id}"$'\n'
        ;;
      pending)
        pend_list="${pend_list}${id}"$'\n'
        ;;
      *)
        live_list="${live_list}${id}"$'\n'
        ;;
    esac
  done < <(find "$ex_dir" -mindepth 1 -maxdepth 1 -type d | sort)

  local npend=0 nlive=0 nexempt=0
  [ -n "$pend_list" ] && npend=$(printf '%s' "$pend_list" | grep -c '' || true)
  [ -n "$live_list" ] && nlive=$(printf '%s' "$live_list" | grep -c '' || true)
  [ -n "$exempt_list" ] && nexempt=$(printf '%s' "$exempt_list" | grep -c '' || true)

  pending_total=$((pending_total + npend))
  exempt_total=$((exempt_total + nexempt))

  if [ ! -f "$cov" ]; then
    if [ "$nlive" -eq 0 ]; then
      echo "[skip] $lang: $total 个用例全部 pending/exempt，无覆盖声明需求"
      echo "  pending $npend 个，exempt $nexempt 个"
      if [ -n "$no_reason" ]; then
        echo "  [FAIL] 以下用例声明了 coverage: exempt 却没写原因（空豁免等于没豁免）：$no_reason"
        bad=$((bad + 1))
      fi
      [ "$bad" -gt 0 ] && failed=$((failed + 1))
      return 0
    fi
    echo "[FAIL] $lang: 缺 $cov（$nlive 个非豁免用例没有任何覆盖声明）"
    failed=$((failed + 1))
    return 0
  fi

  echo "==> 校验 $lang（$total 个用例，pending $npend，exempt $nexempt）"
  if [ -n "$no_reason" ]; then
    echo "  [FAIL] 以下用例声明了 coverage: exempt 却没写原因（空豁免等于没豁免）：$no_reason"
    bad=$((bad + 1))
  fi

  local declared
  declared="$(cov_ids "$cov" | sort -u)"

  # 4) 表不能是空的 —— 只有存在非豁免用例时才要求
  if [ -z "$declared" ] && [ "$nlive" -gt 0 ]; then
    echo "  [FAIL] $cov 里没有任何用例 ID"
    bad=$((bad + 1))
  fi

  # 1) 声明了不存在的用例（pending/exempt 与否都要查，这是防凭空写）
  for id in $declared; do
    if [ ! -d "$ex_dir/$id" ]; then
      echo "  [FAIL] 声明了不存在的用例: $id"
      bad=$((bad + 1))
    fi
  done

  # 2) 每个非豁免用例 ID 必须在 project/ 的代码里出现
  #    排除**所有 *.md**：COVERAGE.md 是自证表，README 里的「覆盖落点」表同样是自证。
  #    原来只排除 COVERAGE.md，于是把 ID 抄进 README.md 的表格就能过 —— 闸门形同虚设
  #    （PROJ-C / PROJ-VUE 两张卡都踩了这个洞：声明 78/46 条，代码里一条都没有）。
  #    只认非文档文件（源码 / 配置 / SQL / 脚本），注释里写 ID 也算，便于追溯。
  local covered=0 missing=0
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    # 注意：--exclude 必须放在 `--` 之前。放在 `--` 之后会被当成文件名，
    # 排除静默失效 —— 那样只要把 ID 写进 COVERAGE.md 表格就自证了。
    if grep -rqF --exclude='*.md' -- "$id" "$lang/project" 2>/dev/null; then
      covered=$((covered + 1))
    else
      echo "  [FAIL] 用例 $id 在 $lang/project/ 的非文档文件里找不到引用（写进 README 不算）"
      missing=$((missing + 1))
    fi
  done <<< "$live_list"
  [ "$missing" -gt 0 ] && bad=$((bad + 1))

  # 3) 反向：每个非豁免用例必须都在表里声明过
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
    echo "  pending $npend 个（未接入 project，非严格模式下豁免，--strict 下算失败）"
    pending_detail="${pending_detail}${lang}: ${npend}"$'\n'
  fi
  if [ "$nexempt" -gt 0 ]; then
    echo "  exempt $nexempt 个（有意不接入，--strict 下仍算通过）"
    exempt_detail="${exempt_detail}${lang}: ${nexempt}"$'\n'
  fi
  [ "$bad" -gt 0 ] && failed=$((failed + 1))
  return 0
}

for l in $LANGS; do
  check_lang "$l" || true
done

echo "------------------------------------------------------------------"
if [ "$exempt_total" -gt 0 ]; then
  echo "有意豁免 $exempt_total 个（--strict 下仍算通过）："
  printf '%s' "$exempt_detail" | sed 's/^/  /'
fi
if [ "$STRICT" -eq 1 ] && [ "$pending_total" -gt 0 ]; then
  echo "STRICT：仍有 $pending_total 个 pending 用例未登记覆盖（阶段 4 收口前必须清零）：" >&2
  printf '%s' "$pending_detail" | sed 's/^/  /' >&2
  failed=$((failed + 1))
fi
if [ "$failed" -ne 0 ]; then
  echo "COVERAGE 校验失败（$failed 个轨道不过）" >&2
  exit 1
fi
if [ "$pending_total" -gt 0 ]; then
  echo "COVERAGE 校验通过（pending $pending_total 个，--strict 下会失败；exempt $exempt_total 个）"
else
  echo "COVERAGE 校验通过（exempt $exempt_total 个）"
fi
