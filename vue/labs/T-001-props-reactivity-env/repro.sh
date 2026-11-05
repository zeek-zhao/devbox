#!/usr/bin/env bash
# T-001-props-reactivity-env 最小复现：一次性坐实两类「构建全绿但产物已坏」的缺陷——
#   ① 解构 props 丢响应性（headless 挂载真跑 + reactivity effect 层隔离）；
#   ② vite build 未声明 env → 产物内联 undefined（void 0）。
# 按 docs/72 §2 样板约定：复现成功 = 证据坐实 = 本脚本以退出码 1 结束，
# 证据行（REACTIVITY-LOST / EFFECT-CONFIRMED / ENV-VOID0-COUNT）原样打到 stdout，
# 由调用方归一化后再断言。产物只写临时目录，不入库。
# 工具链（node/npm）预装在 devbox-vue 镜像里；vue/vite 由内嵌 app/ 工程 npm install。
# 用法：bash repro.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

BUILD="${TMPDIR:-/tmp}/devbox-vue-T-001-props-reactivity-env"
APP="$BUILD/app"
mkdir -p "$BUILD"

pass=0
fail=0

# 0) 准备内嵌最小 vue 工程（不改 examples/；node_modules 只落在临时目录）
rm -rf "$APP"
cp -r app "$APP"
(cd "$APP" && npm install --no-audit --no-fund --loglevel=error >/dev/null 2>&1) || {
  echo "repro: npm install 失败（容器需可访问 npm registry，见 WALKTHROUGH 停止条件）" >&2
  exit 2
}

# 1) headless 挂载真跑：解构 props 丢响应性（复现成功 = 退出码 1）
out="$(cd "$APP" && node src/props-repro.mjs 2>&1)"
rc=$?
printf '%s\n' "$out"
if [ "$rc" -eq 1 ] && grep -q 'REACTIVITY-LOST' <<<"$out" && grep -q 'text buggy=1 good=2' <<<"$out"; then
  pass=$((pass + 1))
else
  echo "repro: 挂载真跑未坐实丢响应性（rc=$rc）" >&2
  fail=$((fail + 1))
fi

# 2) reactivity effect 层隔离：代理读被追踪、解构快照读不被追踪（复现成功 = 退出码 1）
out="$(cd "$APP" && node src/effect-isolate.mjs 2>&1)"
rc=$?
printf '%s\n' "$out"
if [ "$rc" -eq 1 ] && grep -q 'EFFECT proxy-read=2 destructured-read=1' <<<"$out"; then
  pass=$((pass + 1))
else
  echo "repro: effect 隔离实验未坐实（rc=$rc）" >&2
  fail=$((fail + 1))
fi

# 3) vite build（未声明 env）：产物里静态搜 void 0（构建产物级证据）
(cd "$APP" && npx vite build >/dev/null 2>&1) || {
  echo "repro: vite build 失败" >&2
  exit 2
}
bundle="$(find "$APP/dist/assets" -maxdepth 1 -name '*.js' 2>/dev/null | head -1)"
if [ -n "$bundle" ]; then
  void0="$(grep -o 'void 0' "$bundle" | wc -l | tr -d ' ')"
  hashname="$(basename "$bundle" | sed -E 's/index-[A-Za-z0-9_-]+\.js/index-HASH.js/')"
  echo "ENV-VOID0-COUNT=$void0 (undeclared env, bundle: $hashname)"
  grep -o '.\{0,24\}void 0.\{0,12\}' "$bundle" | head -2 | sed 's/^/  | /'
  if [ "${void0:-0}" -ge 1 ]; then
    pass=$((pass + 1))
  else
    echo "repro: 产物未命中 void 0（vite 版本漂移？登记 UNVERIFIED）" >&2
    fail=$((fail + 1))
  fi
else
  echo "repro: dist/assets 无 js 产物" >&2
  fail=$((fail + 1))
fi

# 复现成功 = 证据坐实 = 非零退出码（docs/72 §2，与 cpp/go 样板一致）
if [ "$fail" -eq 0 ] && [ "$pass" -eq 3 ]; then
  echo "REPRO-CONFIRMED: 3/3 证据坐实（按样板纪律退出码 1 = 故障在场）"
  exit 1
fi
echo "REPRO-BROKEN: $pass/3 证据坐实，$fail 项不符（环境异常，交维护者）" >&2
exit 3
