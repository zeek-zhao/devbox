#!/usr/bin/env bash
# ==================================================================
# 门禁文件守卫（本地版，替代原 ci.yml 里的 gate job）
# ------------------------------------------------------------------
# 为什么搬到本地：PR 阶段不再触发任何流水线（见 docs/02-CI分级.md），
# 所以「有没有人偷偷改判定标准」这件事必须由合并前总闸来问。
#
# 关键点：清单读的是 **base 分支的版本**，不是当前工作树的版本。
# 否则 AI 可以先把自己加进白名单、或把清单删空，再动门禁文件 ——
# 那样这道闸就成了摆设。
#
# 用法：
#   bash scripts/check-gate-files.sh              # base 默认 origin/main
#   bash scripts/check-gate-files.sh origin/dev   # 换基线
#   bash scripts/check-gate-files.sh --list       # 只打印清单，不比对
#   bash scripts/check-gate-files.sh --self       # 比对当前分支相对 base 的改动
#
# 退出码：
#   0  未触碰门禁文件
#   1  触碰了（自动合并必须被拒绝）
#   2  环境/参数问题（base 不存在、清单缺失）—— 不许当成「通过」
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE="origin/main"
LIST_ONLY=0
for a in "$@"; do
  case "$a" in
    --list) LIST_ONLY=1 ;;
    -*) echo "未知选项: $a" >&2; exit 2 ;;
    *) BASE="$a" ;;
  esac
done

if [ "$LIST_ONLY" -eq 1 ]; then
  cat scripts/gate-files.txt
  exit 0
fi

# 基线必须是个能解析的 ref。解析不了就 exit 2 —— 绝不能静默变成「没有改动」，
# 那样每次都会判绿（这是本项目踩过的 CRLF 教训的同型坑）。
if ! git rev-parse --verify -q "$BASE^{commit}" >/dev/null; then
  echo "ERROR: 基线 ref 无效：'$BASE'（先 git fetch origin）" >&2
  exit 2
fi

if ! git cat-file -e "$BASE:scripts/gate-files.txt" 2>/dev/null; then
  echo "ERROR: $BASE 上没有 scripts/gate-files.txt，无法判定门禁" >&2
  exit 2
fi

LIST="$(mktemp)"
CHANGED="$(mktemp)"
trap 'rm -f "$LIST" "$CHANGED"' EXIT

git show "$BASE:scripts/gate-files.txt" > "$LIST"
git diff --name-only "$BASE...HEAD" > "$CHANGED"

# 判据为空说明 diff 本身出问题（比如基线写错），不能当成「没改门禁」
if [ ! -s "$CHANGED" ]; then
  echo "ERROR: $BASE...HEAD 的差异为空，判据不可信，拒绝判定" >&2
  exit 2
fi

echo "==> 门禁文件比对（基线 $BASE，改动 $(grep -c '' "$CHANGED") 个文件）"

hits=()
while IFS= read -r pat; do
  case "$pat" in ''|'#'*) continue ;; esac
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    # shellcheck disable=SC2254  # 这里就是要用变量当 glob（* 可跨目录）
    case "$f" in $pat) hits+=("$f") ;; esac
  done < "$CHANGED"
done < "$LIST"

if [ "${#hits[@]}" -gt 0 ]; then
  echo "本分支触碰了门禁文件：" >&2
  printf '  %s\n' "${hits[@]}" >&2
  echo >&2
  echo "确需改动时，由人评审后在合并时显式加 --allow-gate-change，并在提交信息里写明为什么改。" >&2
  exit 1
fi

echo "未触碰门禁文件"
