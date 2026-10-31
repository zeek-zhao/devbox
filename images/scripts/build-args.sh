#!/usr/bin/env bash
# ==================================================================
# 把 images/versions.env 翻译成 docker 的 --build-arg 参数对
# ------------------------------------------------------------------
# 为什么不用 `docker buildx build --build-arg-file`：
#   215 上的 buildx 与 GitHub runner 上的 buildx 插件版本都偏旧，
#   直接报 `unknown flag: --build-arg-file`（exit 125）。
#   所以统一走「自己解析 → 拼 --build-arg」这条最保守的路。
#
# 输出：一行两个 token（--build-arg 和 K=V），调用方直接展开：
#   mapfile -t ARGS < <(bash images/scripts/build-args.sh)
#   docker buildx build ... "${ARGS[@]}"
#
# 规则：
#   - 跳过空行与整行注释（值里的 # 不处理，避免误伤 URL）
#   - 跳过 REGISTRY（它不是 Dockerfile 的 ARG，只用于镜像命名）
#   - 跳过空值（避免用空串盖掉 Dockerfile 里的默认值）
# ==================================================================
set -euo pipefail

file="${1:-images/versions.env}"

[ -f "$file" ] || { echo "找不到版本文件：$file" >&2; exit 2; }

while IFS= read -r raw || [ -n "$raw" ]; do
  line="${raw%$'\r'}"
  case "$line" in
    ''|'#'*) continue ;;
  esac
  key="${line%%=*}"
  val="${line#*=}"
  case "$key" in
    ''|REGISTRY) continue ;;
  esac
  [ -n "$val" ] || continue
  printf -- '--build-arg\n%s=%s\n' "$key" "$val"
done < "$file"
