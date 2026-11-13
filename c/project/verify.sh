#!/usr/bin/env bash
# 毕业项目统一验证入口（#394 · M13-CONTENT-01）
#
# 契约：`bash <lang>/project/verify.sh`
#   在**本轨镜像**内跑「构建 → 自检」——镜像里的工具链版本才是项目的真本。
#   本机无 docker 或镜像不在本地时回退当前环境并打印 [warn]（工具链版本不符会如实 fail）。
# 判定：逐条 [pass]/[fail] 走 stderr，末行 `<通过数>/<判定数> 判定符合预期` 也走 stderr；
#       stdout 留给业务程序本身（python/rust 会打满整屏，故判定不能混进去）。
# 纪律：构建产物落容器内 /tmp 副本，仓库保持干净；只做「跑」，不改业务代码。
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="ghcr.io/zeek-zhao/devbox-cpp:${TAG:-latest}"

pass=0
total=0
check() {
  local name="$1"
  shift
  total=$((total + 1))
  if "$@"; then
    pass=$((pass + 1))
    printf '[pass] %s\n' "$name" >&2
  else
    printf '[fail] %s\n' "$name" >&2
  fi
}

USE_DOCKER=0
if command -v docker >/dev/null 2>&1 && docker image inspect "$IMAGE" >/dev/null 2>&1; then
  USE_DOCKER=1
  printf '[info] 镜像内运行：%s\n' "$IMAGE" >&2
else
  printf '[warn] 无 docker 或镜像不在本地：%s，回退宿主环境\n' "$IMAGE" >&2
fi

# 在容器内执行一段构建脚本（产物落 /tmp/p），或在本机直接执行
in_container() {
  docker run --rm -v "$ROOT:/src:ro" "$IMAGE" bash -c "$1"
}
run_step() {
  if [ "$USE_DOCKER" -eq 1 ]; then
    in_container "set -uo pipefail; [ -d /tmp/p ] || cp -a /src /tmp/p; cd /tmp/p; $1"
  else
    (cd "$ROOT" && bash -c "$1")
  fi
}

check "Makefile 存在" test -f "$ROOT/Makefile"
check "构建+冒烟+自检通过" run_step 'make -s all && bash test/smoke.sh && ./devbox-c-server --selftest'

printf '%d/%d 判定符合预期\n' "$pass" "$total" >&2
[ "$pass" -eq "$total" ]
