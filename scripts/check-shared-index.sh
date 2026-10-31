#!/usr/bin/env bash
# 校验 shared/README.md 的函数索引与 shared/lib/*.sh 的实际函数一致。
#
# 判据（单向）：lib 里定义的每个公开函数（不以 _ 开头）都必须出现在 README 里。
# 反向不校验 —— 文档里提到历史函数名、或写示例代码，都是正常的。
#
# 存在的意义：工具箱最容易烂的地方是「代码加了函数，文档还是老的」，
# 而下一个人靠文档判断能不能用。这条检查把「文档撒谎」变成 CI 红。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$ROOT/shared/README.md"

if [[ ! -f "$README" ]]; then
  echo "FAIL: 缺 $README" >&2
  exit 1
fi

total=0
missing=0

for f in "$ROOT"/shared/lib/*.sh; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  # 抓行首的 name() 定义，排除下划线开头的私有函数
  while IFS= read -r fn; do
    [[ -n "$fn" ]] || continue
    total=$((total + 1))
    if ! grep -qF "$fn" "$README"; then
      printf '  ✗ %-16s (%s) 未出现在 shared/README.md 的函数索引里\n' "$fn" "$base" >&2
      missing=$((missing + 1))
    fi
  done < <(grep -oE '^[a-zA-Z][a-zA-Z0-9_]*\(\)' "$f" | sed 's/()$//')
done

if ((total == 0)); then
  echo "FAIL: shared/lib/*.sh 里一个函数都没扫到，检查脚本本身" >&2
  exit 1
fi

if ((missing > 0)); then
  echo "FAIL: $missing/$total 个函数没写进 shared/README.md" >&2
  exit 1
fi

printf 'shared 函数索引 OK（%d 个函数，全部有文档）\n' "$total"
