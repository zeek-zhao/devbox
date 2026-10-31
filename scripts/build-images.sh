#!/usr/bin/env bash
# ==================================================================
# 镜像构建入口（215 上迭代用；CI 用的是 .github/workflows/images.yml，逻辑等价）
# ------------------------------------------------------------------
# 用法：
#   scripts/build-images.sh                    # 全部按序构建
#   scripts/build-images.sh --only base,tool   # 只建指定层
#   scripts/build-images.sh --push             # 推送到 ${REGISTRY}
#   scripts/build-images.sh --tag ci-abc123
# 设计要点：
#   1) 版本号全部来自 images/versions.env，用 --build-arg-file 传入，脚本不重复写版本
#   2) 每层建完记录真实体积到 metrics/images.tsv，超预算告警
#   3) 分层顺序：base -> tool -> 6 语言 -> all -> runtime
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="local"
PUSH=0
ONLY=""
BUILD_ARGS_FILE="images/versions.env"

while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    --push) PUSH=1; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

# REGISTRY 从 versions.env 取，也可用环境变量覆盖
REGISTRY="${REGISTRY:-$(grep -E '^REGISTRY=' "$BUILD_ARGS_FILE" | cut -d= -f2)}"
PREFIX="${REGISTRY:+${REGISTRY}/}"

mkdir -p metrics
TSV="metrics/images.tsv"
[ -f "$TSV" ] || printf 'timestamp\tlayer\ttag\tsize_bytes\tsize_human\tduration_s\n' > "$TSV"

# 体积预算（字节）。超 15% 告警，阶段 0 实测后回填真实值
budget_bytes() {
  case "$1" in
    base)    echo $((1200*1024*1024)) ;;
    tool)    echo $((2600*1024*1024)) ;;
    cpp)     echo $((4200*1024*1024)) ;;
    go)      echo $((3400*1024*1024)) ;;
    rust)    echo $((4200*1024*1024)) ;;
    shell)   echo $((2800*1024*1024)) ;;
    python)  echo $((3200*1024*1024)) ;;
    java)    echo $((4000*1024*1024)) ;;
    all)     echo $((11000*1024*1024)) ;;
    runtime) echo $((900*1024*1024)) ;;
    *)       echo $((10*1024*1024*1024)) ;;
  esac
}

should_build() {
  [ -z "$ONLY" ] && return 0
  case ",${ONLY}," in *",$1,"*) return 0 ;; *) return 1 ;; esac
}

build_layer() {
  local layer="$1" base_image="$2"
  should_build "$layer" || { echo "-- 跳过 $layer"; return 0; }

  local image="${PREFIX}devbox-${layer}:${TAG}"
  echo "=================================================================="
  echo ">>> 构建 ${image}  (FROM ${base_image})"
  echo "=================================================================="

  local start end dur
  start="$(date +%s)"
  docker build \
    --file "images/${layer}/Dockerfile" \
    --build-arg "BASE_IMAGE=${base_image}" \
    --build-arg-file "$BUILD_ARGS_FILE" \
    --tag "$image" \
    --label "devbox.tag=${TAG}" \
    .
  end="$(date +%s)"; dur=$((end-start))

  local size human budget
  size="$(docker image inspect "$image" --format '{{.Size}}')"
  human="$(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "${size}B")"
  budget="$(budget_bytes "$layer")"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(date -Iseconds)" "$layer" "$TAG" "$size" "$human" "$dur" >> "$TSV"
  echo ">>> ${layer}: ${human}  (预算 $(numfmt --to=iec --suffix=B "$budget"), 耗时 ${dur}s)"

  if [ "$size" -gt $((budget * 115 / 100)) ]; then
    echo "!!! 体积超预算 15%: ${layer} = ${human}" >&2
    BUDGET_FAIL=1
  fi

  if [ "$PUSH" = "1" ]; then
    echo ">>> 推送 ${image}"
    docker push "$image"
  fi
}

BUDGET_FAIL=0
LANGS="cpp go rust shell python java"

base_img="${PREFIX}devbox-base:${TAG}"
tool_img="${PREFIX}devbox-tool:${TAG}"

build_layer base ubuntu
build_layer tool "$base_img"

# 6 个语言镜像并行构建（彼此无依赖，共享 tool 层的缓存）
pids=()
for lang in $LANGS; do
  should_build "$lang" || continue
  ( build_layer "$lang" "$tool_img" ) &
  pids+=($!)
done
for pid in "${pids[@]:-}"; do
  [ -n "$pid" ] && wait "$pid" || true
done

build_layer all "$tool_img"
build_layer runtime ubuntu

echo
echo "=================================================================="
echo "构建完成，体积台账："
column -t -s $'\t' "$TSV" | tail -12
if [ "$BUDGET_FAIL" != "0" ]; then
  echo "!! 有层超出体积预算，见上方告警" >&2
  exit 3
fi
