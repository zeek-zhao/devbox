#!/usr/bin/env bash
# 用例 hello —— 验证 shell 镜像的 bash 5.2 + 严格模式基线
set -euo pipefail
IFS=$'\n\t'

echo "[hello] Shell from devbox"

# 数组：shell 里最常被写错的东西之一
names=(alpha beta gamma)
echo "array_len = ${#names[@]}"

# 算术：$(( )) 而不是 expr
sum=0
for i in $(seq 1 100); do
  sum=$((sum + i))
done
echo "sum(1..100) = ${sum}"

# 命令替换 + 退出码判定：$? 不要直接信，要 if 包住
if out=$(printf '%s' "ok") && [ "${out}" = "ok" ]; then
  echo "status = 0"
fi
