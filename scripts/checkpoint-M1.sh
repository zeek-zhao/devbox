#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REGISTRY="ghcr.io/zeek-zhao"
NO_PULL=0
ONLY=""
TOL="15"
LAYERS=(base tool cpp go rust shell python java all runtime)
declare -A smoke_commands=(
  [base]='git --version && locale | grep -q "LANG=en_US.UTF-8"'
  [tool]='gdb --version | head -1 && valgrind --version'
  [cpp]='gcc --version | head -1 && clang --version | head -1 && cmake --version | head -1'
  [go]='go version'
  [rust]='rustc -V && cargo clippy -V'
  [shell]='bats --version && shellcheck --version | grep ^version'
  [python]='python3 -V && uv --version && ruff --version'
  [java]='java -version 2>&1 | head -1 && mvn -V 2>&1 | head -1'
  [all]='gcc --version | head -1 && go version && rustc -V && python3 -V && javac -version && bats --version'
  [runtime]='ldconfig -p | grep -q libstdc++ && ! command -v gcc && ! command -v javac'
)

usage() {
  printf '用法：bash scripts/checkpoint-M1.sh [--registry R] [--no-pull] [--only L1,L2] [--tol N]\n'
}

fail() {
  printf '错误：%s\n' "$1" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --registry|--only|--tol)
      option="$1"
      if [ "$#" -lt 2 ] || [[ "$2" == --* ]]; then
        fail "$option 缺少参数"
      fi
      value="$2"
      case "$option" in
        --registry) REGISTRY="$value" ;;
        --only) ONLY="$value" ;;
        --tol) TOL="$value" ;;
      esac
      shift 2
      ;;
    --no-pull)
      NO_PULL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "未知参数：$1"
      ;;
  esac
done

[[ -n "$REGISTRY" ]] || fail "--registry 不能为空"
REGISTRY="${REGISTRY%/}"
[[ "$TOL" =~ ^[0-9]+$ ]] || fail "--tol 必须是非负整数"

if [ -n "$ONLY" ]; then
  selected_layers=()
  IFS=',' read -r -a requested_layers <<< "$ONLY"
  [ "${#requested_layers[@]}" -gt 0 ] || fail "--only 不能为空"
  for requested_layer in "${requested_layers[@]}"; do
    [[ -n "${smoke_commands[$requested_layer]+present}" ]] ||
      fail "--only 包含未知层：$requested_layer"
    selected_layers+=("$requested_layer")
  done
else
  selected_layers=("${LAYERS[@]}")
fi

declare -A pull_status=()
declare -A volume_status=()
declare -A smoke_status=()
overall_failed=0

for layer in "${selected_layers[@]}"; do
  image="${REGISTRY}/devbox-${layer}:latest"
  if [ "$NO_PULL" -eq 1 ]; then
    pull_status["$layer"]="跳过"
  elif pull_output="$(docker pull "$image" 2>&1)"; then
    pull_status["$layer"]="通过"
    printf '拉取 %s：\n%s\n' "$layer" "$pull_output"
  else
    pull_rc=$?
    pull_status["$layer"]="失败"
    overall_failed=1
    printf '拉取失败（层：%s，镜像：%s，退出码：%s）：\n%s\n' \
      "$layer" "$image" "$pull_rc" "$pull_output" >&2
  fi
done

printf '==> 体积检查（budget-check.sh，tol=%s）\n' "$TOL"
if budget_output="$(bash scripts/budget-check.sh --registry "$REGISTRY" --tol "$TOL" 2>&1)"; then
  budget_rc=0
else
  budget_rc=$?
fi
printf '%s\n' "$budget_output"

for layer in "${selected_layers[@]}"; do
  volume_status["$layer"]="失败"
  while IFS= read -r line; do
    if [[ "$line" == "$layer "* ]]; then
      if [[ "$line" == *"通过"* ]]; then
        volume_status["$layer"]="通过"
      elif [[ "$line" == *"超预算"* ]]; then
        volume_status["$layer"]="失败"
      fi
      break
    fi
  done <<< "$budget_output"
  if [ "${volume_status[$layer]}" != "通过" ]; then
    overall_failed=1
  fi
done
if [ "$budget_rc" -ne 0 ]; then
  overall_failed=1
fi

for layer in "${selected_layers[@]}"; do
  image="${REGISTRY}/devbox-${layer}:latest"
  printf 'Smoke %s：\n' "$layer"
  if smoke_output="$(docker run --rm "$image" bash -lc "${smoke_commands[$layer]}" 2>&1)"; then
    smoke_status["$layer"]="通过"
    printf '%s\n' "$smoke_output"
  else
    smoke_rc=$?
    smoke_status["$layer"]="失败"
    overall_failed=1
    printf '失败（退出码：%s）\n%s\n' "$smoke_rc" "$smoke_output" >&2
  fi
done

printf '\n%-10s %-10s %-10s %-10s %s\n' "层" "拉取" "体积" "smoke" "判定"
for layer in "${selected_layers[@]}"; do
  decision="通过"
  if [ "${pull_status[$layer]}" = "失败" ] ||
    [ "${volume_status[$layer]}" != "通过" ] ||
    [ "${smoke_status[$layer]}" != "通过" ]; then
    decision="失败"
    overall_failed=1
  fi
  printf '%-10s %-10s %-10s %-10s %s\n' \
    "$layer" "${pull_status[$layer]}" "${volume_status[$layer]}" \
    "${smoke_status[$layer]}" "$decision"
done

if [ "$overall_failed" -ne 0 ]; then
  exit 1
fi
