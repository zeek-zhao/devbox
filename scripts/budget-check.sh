#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUDGETS="images/budgets.tsv"
METRICS=""
REGISTRY="ghcr.io/zeek-zhao"
TOL="15"
EXPECTED_LAYERS=(base tool cpp go rust shell python java all runtime)
LAYERS=""
LAYERS_SET=0

fail() {
  printf '配置/数据错误：%s\n' "$1" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --budgets|--metrics|--registry|--tol|--layers)
      option="$1"
      if [ "$#" -lt 2 ] || [[ "$2" == --* ]]; then
        fail "$option 缺少参数"
      fi
      value="$2"
      case "$option" in
        --budgets) BUDGETS="$value" ;;
        --metrics) METRICS="$value" ;;
        --registry) REGISTRY="$value" ;;
        --tol) TOL="$value" ;;
        --layers)
          LAYERS="$value"
          LAYERS_SET=1
          ;;
      esac
      shift 2
      ;;
    *)
      fail "未知参数：$1"
      ;;
  esac
done

[[ "$TOL" =~ ^[0-9]+$ ]] || fail "--tol 必须是非负整数"
[[ -n "$REGISTRY" ]] || fail "--registry 不能为空"
REGISTRY="${REGISTRY%/}"
CHECK_LAYERS=("${EXPECTED_LAYERS[@]}")
if [ "$LAYERS_SET" -eq 1 ]; then
  [ -n "$LAYERS" ] || fail "--layers 不能为空"
  [[ "$LAYERS" != ,* && "$LAYERS" != *, && "$LAYERS" != *,,* ]] ||
    fail "--layers 包含空层名"
  IFS=',' read -r -a CHECK_LAYERS <<< "$LAYERS"
  [ "${#CHECK_LAYERS[@]}" -gt 0 ] || fail "--layers 不能为空"
  declare -A selected_layer_seen=()
  for layer in "${CHECK_LAYERS[@]}"; do
    [[ -n "$layer" ]] || fail "--layers 包含空层名"
    [[ -n "${selected_layer_seen[$layer]+present}" ]] && fail "--layers 重复层：$layer"
    selected_layer_seen["$layer"]=1
    known_layer=0
    for expected_layer in "${EXPECTED_LAYERS[@]}"; do
      if [ "$layer" = "$expected_layer" ]; then
        known_layer=1
        break
      fi
    done
    [ "$known_layer" -eq 1 ] || fail "--layers 包含未知层：$layer"
  done
fi
[[ -f "$BUDGETS" ]] || fail "预算表不存在：$BUDGETS"
if [ -n "$METRICS" ]; then
  [[ -f "$METRICS" ]] || fail "metrics 文件不存在：$METRICS"
fi

declare -A budget_by_layer=()
budget_layers=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  [[ "$line" == *$'\t'* ]] || fail "预算行不是两列 TSV：$line"
  layer="${line%%$'\t'*}"
  budget="${line#*$'\t'}"
  [[ -n "$layer" && "$budget" != *$'\t'* && -n "$budget" ]] ||
    fail "预算行不是两列 TSV：$line"
  [[ "$budget" =~ ^[0-9]+$ ]] || fail "$layer 的预算不是非负整数：$budget"
  [[ ! "$budget" =~ ^0+$ ]] || fail "$layer 的预算必须大于零"
  [[ -z "${budget_by_layer[$layer]+present}" ]] || fail "预算表重复层：$layer"
  budget_by_layer["$layer"]="$budget"
  budget_layers+=("$layer")
done < "$BUDGETS"

if [ "${#budget_layers[@]}" -ne "${#EXPECTED_LAYERS[@]}" ]; then
  fail "预算表必须恰有 ${#EXPECTED_LAYERS[@]} 层，实际 ${#budget_layers[@]} 层"
fi
for index in "${!EXPECTED_LAYERS[@]}"; do
  [ "${budget_layers[$index]}" = "${EXPECTED_LAYERS[$index]}" ] ||
    fail "预算层名或顺序错误：第 $((index + 1)) 层应为 ${EXPECTED_LAYERS[$index]}"
done

declare -A size_by_layer=()
if [ -n "$METRICS" ]; then
  metrics_header_seen=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" ]] && continue
    if [ "$metrics_header_seen" -eq 0 ]; then
      [ "$line" = $'layer\tsize_bytes' ] || fail "metrics 首行必须是 layer<TAB>size_bytes"
      metrics_header_seen=1
      continue
    fi
    [[ "$line" == *$'\t'* ]] || fail "metrics 行不是两列 TSV：$line"
    layer="${line%%$'\t'*}"
    size="${line#*$'\t'}"
    [[ -n "$layer" && "$size" != *$'\t'* && -n "$size" ]] ||
      fail "metrics 行不是两列 TSV：$line"
    [[ -n "${budget_by_layer[$layer]+present}" ]] || fail "metrics 包含未知层：$layer"
    [[ "$size" =~ ^[0-9]+$ ]] || fail "$layer 的实测体积不是非负整数：$size"
    [[ -z "${size_by_layer[$layer]+present}" ]] || fail "metrics 重复层：$layer"
    size_by_layer["$layer"]="$size"
  done < "$METRICS"
  [ "$metrics_header_seen" -eq 1 ] || fail "metrics 文件缺少表头"
else
  for layer in "${CHECK_LAYERS[@]}"; do
    image="${REGISTRY}/devbox-${layer}:latest"
    if ! size="$(docker image inspect "$image" --format '{{.Size}}')"; then
      fail "无法读取镜像体积：$image"
    fi
    [[ "$size" =~ ^[0-9]+$ ]] || fail "$image 返回了无效体积：$size"
    size_by_layer["$layer"]="$size"
  done
fi

printf '%-10s %16s %16s %10s  %s\n' "层" "实测（字节）" "预算（字节）" "余量%" "判定"
failed=0
missing=0
for layer in "${CHECK_LAYERS[@]}"; do
  if [[ -z "${size_by_layer[$layer]+present}" ]]; then
    printf '%-10s %16s %16s %10s  %s\n' "$layer" "-" "${budget_by_layer[$layer]}" "-" "缺少 metrics"
    missing=$((missing + 1))
    continue
  fi
  size="${size_by_layer[$layer]}"
  budget="${budget_by_layer[$layer]}"
  result="$(awk -v size="$size" -v budget="$budget" -v tol="$TOL" '
    BEGIN {
      threshold = budget * (100 + tol) / 100
      margin = (budget - size) * 100 / budget
      if (size > threshold) {
        printf "%.2f\t1\t%.0f\n", margin, size - threshold
      } else {
        printf "%.2f\t0\t0\n", margin
      }
    }')"
  IFS=$'\t' read -r margin is_over excess <<< "$result"
  decision="通过"
  if [ "$is_over" -eq 1 ]; then
    decision="超预算（超阈值 ${excess} B）"
    failed=$((failed + 1))
  fi
  printf '%-10s %16s %16s %9s%%  %s\n' \
    "$layer" "$size" "$budget" "$margin" "$decision"
done

if [ "$failed" -gt 0 ]; then
  printf '%-10s %16s %16s %10s  %s\n' "" "" "" "" "汇总：${failed} 层超预算"
  exit 1
fi
if [ "$missing" -gt 0 ]; then
  printf '%-10s %16s %16s %10s  %s\n' "" "" "" "" "汇总：缺少 ${missing} 层 metrics"
  exit 2
fi
printf '%-10s %16s %16s %10s  %s\n' "" "" "" "" "汇总：全部在预算内"
