#!/usr/bin/env bash
# ==================================================================
# 文档命令校验（防止文档里的命令随 make 目标改名而静默失效）
# ------------------------------------------------------------------
# 约定：在 Markdown 里给可执行的示例加一行 HTML 注释
#
#   <!-- verify: make help -->
#
# 本脚本扫出全部标记，从仓库根逐条真跑，任何一条非零退出即判失败。
#
# 只标记「在任何环境下都该成功」的命令（帮助、列表、只读探测）。
# 不要标记会因环境差异失败的命令（构建、拉镜像、跑用例）。
#
# 为什么需要它：文档里写错的命令不会报错，只会让人照着敲一遍才发现不对，
# 而那时已经浪费了一次上下文切换。让 CI 替你敲。
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TIMEOUT_SEC="${TIMEOUT_SEC:-120}"

# 扫描范围：根 README、仓库级文档、shared 说明（尚未创建则跳过）
targets=()
for f in README.md docs/*.md shared/README.md; do
  [ -f "$f" ] && targets+=("$f")
done

if [ "${#targets[@]}" -eq 0 ]; then
  echo "没有找到任何待校验文档" >&2
  exit 2
fi

echo "==> 文档命令校验（扫描 ${#targets[@]} 个文件）"

total=0
failed=0
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

for f in "${targets[@]}"; do
  # 提取所有 <!-- verify: CMD --> 里的 CMD
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    total=$((total + 1))

    if timeout "$TIMEOUT_SEC" bash -c "$cmd" >"$tmp" 2>&1; then
      printf '  OK    %-24s %s\n' "$f" "$cmd"
    else
      failed=$((failed + 1))
      printf '  FAIL  %-24s %s\n' "$f" "$cmd"
      sed 's/^/        /' "$tmp" | head -8
    fi
  done < <(
    grep -oE '<!--[[:space:]]*verify:[[:space:]]*[^>]*-->' "$f" 2>/dev/null \
      | sed -E 's/^<!--[[:space:]]*verify:[[:space:]]*//; s/[[:space:]]*-->$//' \
      || true
  )
done

echo
if [ "$total" -eq 0 ]; then
  echo "汇总：一个 <!-- verify: ... --> 标记都没有，本检查等于空转" >&2
  echo "      要么补标记，要么把本脚本从 CI 里去掉 —— 不要留一个永远通过的门禁" >&2
  exit 2
fi

if [ "$failed" -gt 0 ]; then
  echo "汇总：${failed}/${total} 条文档命令失败" >&2
  exit 1
fi

echo "汇总：${total} 条文档命令全部通过"
