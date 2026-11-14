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
IMAGE="ghcr.io/zeek-zhao/devbox-vue:${TAG:-latest}"

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
IMAGE_OK=0
if command -v docker >/dev/null 2>&1; then
  # 本地没有就先 pull（CI 上镜像永远不在本地，attempt2 run 43372723028 实测教训：
  # labs job 显式 docker pull 所以绿，本 job 没拉就全轨「镜像不可用」）。
  docker image inspect "$IMAGE" >/dev/null 2>&1 || docker pull "$IMAGE" >/dev/null 2>&1
  docker image inspect "$IMAGE" >/dev/null 2>&1 && IMAGE_OK=1
fi
if [ "$IMAGE_OK" -eq 1 ]; then
  USE_DOCKER=1
  printf '[info] 镜像内运行：%s\n' "$IMAGE" >&2
elif [ "${CI:-}" = "true" ]; then
  # CI 上镜像必须由本 job 显式拉取（#394）：静默回退宿主会让工具链版本失真，
  # 判据就失去意义（runner 的 javac 11 会如实 fail release 21，看起来像项目坏了）。
  IMAGE_MISSING=1
  printf '[fail] CI 环境下镜像不可用：%s（本 job 应先 docker/login-action + 拉取镜像）\n' "$IMAGE" >&2
else
  printf '[warn] 无 docker 或镜像不在本地：%s，回退宿主环境\n' "$IMAGE" >&2
fi

# 在容器内执行一段构建脚本（产物落 /tmp/p），或在本机直接执行
in_container() {
  docker run --rm -v "$ROOT:/src:ro" "$IMAGE" bash -c "$1"
}
run_step() {
  if [ "${IMAGE_MISSING:-0}" -eq 1 ]; then
    printf '[fail] 跳过：CI 下镜像不可用，不允许回退宿主环境\n' >&2
    return 1
  fi
  if [ "$USE_DOCKER" -eq 1 ]; then
    in_container "set -uo pipefail; [ -d /tmp/p ] || cp -a /src /tmp/p; cd /tmp/p; $1"
  else
    (cd "$ROOT" && bash -c "$1")
  fi
}

check "package.json 存在" test -f "$ROOT/package.json"
check "依赖安装+冒烟通过" run_step 'npm ci --no-audit --no-fund && bash test/smoke.sh'

printf '%d/%d 判定符合预期\n' "$pass" "$total" >&2
[ "$pass" -eq "$total" ]
