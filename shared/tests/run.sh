#!/usr/bin/env bash
# shared/tests 的测试入口。依赖 bats + jq + yq：
#   * 宿主三件套齐全 → 直接跑
#   * 缺依赖但有 docker → 自动进 devbox-shell 镜像重跑（镜像里都装好了）
#   * 都不行 → exit 2 并说清缺什么
#
# 用法: bash shared/tests/run.sh [bats 参数...]
#   例: bash shared/tests/run.sh --filter json
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

missing=()
for t in bats jq yq; do
  command -v "$t" >/dev/null 2>&1 || missing+=("$t")
done

if ((${#missing[@]} > 0)); then
  if command -v docker >/dev/null 2>&1; then
    TAG="${TAG:-latest}"
    IMAGE="${IMAGE:-ghcr.io/zeek-zhao/devbox-shell:${TAG}}"
    if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
      echo "宿主缺 ${missing[*]}，且镜像 $IMAGE 不存在" >&2
      echo "先构建: make build-lang LANG=shell TAG=${TAG}" >&2
      exit 2
    fi
    echo "宿主缺 ${missing[*]} → 改用容器 $IMAGE" >&2
    exec docker run --rm \
      -e NO_COLOR="${NO_COLOR:-}" \
      -v "$ROOT:/work" -w /work/shared \
      "$IMAGE" bash tests/run.sh "$@"
  fi
  echo "缺少依赖: ${missing[*]}（也没有 docker 可以兜底）" >&2
  exit 2
fi

cd "$HERE" || exit 2

# 显式列文件，不要传 `.`：bats 1.10 对 `.` 会直接输出 `1..0`（一个用例都不跑），
# 看着像「全过」，其实什么都没测。
if (($# > 0)); then
  exec bats --print-output-on-failure "$@"
fi

shopt -s nullglob
files=(./test_*.bats)
shopt -u nullglob
if ((${#files[@]} == 0)); then
  echo "没找到 test_*.bats（目录: $HERE）" >&2
  exit 2
fi
exec bats --print-output-on-failure "${files[@]}"
