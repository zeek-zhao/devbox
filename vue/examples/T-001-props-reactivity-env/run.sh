#!/usr/bin/env bash
# T-001-props-reactivity-env 演练入口：串起三种检测手段 + 两段修复对照——
#   step2 headless 挂载真跑（Vue 运行时观测：渲染计数 + 文本快照对照）
#   step3 reactivity effect 隔离（@vue/reactivity 原语层对照）
#   step4 vite build + 产物静态 grep（未声明 env → void 0）
#   step5 修复对照 A：声明 env 后 rebuild（void 0 归零、字符串字面内联）
#   step6 修复对照 B：不解构 props（sed 补丁副本真跑，REACTIVITY-OK）
# 工具链（node/npm）预装在 devbox-vue 镜像里，请在容器内运行，例如：
#   docker run --rm -v "$PWD":/w -w /w \
#     ghcr.io/zeek-zhao/devbox-vue:latest bash vue/examples/T-001-props-reactivity-env/run.sh
# 产物只写临时目录，不入库。用法：bash run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

BUILD="${TMPDIR:-/tmp}/devbox-vue-T-001-props-reactivity-env"
APP="$BUILD/app"
FIX="$BUILD/app-fixed"
mkdir -p "$BUILD"

pass=0
total=6

step() {
  echo
  echo "=== [step $1] $2 ==="
}
ok() {
  echo "  -> 符合预期"
  pass=$((pass + 1))
}
bad() { echo "  -> 不符合预期：$1" >&2; }

install_app() {
  rm -rf "$1"
  cp -r app "$1"
  (cd "$1" && npm install --no-audit --no-fund --loglevel=error >/dev/null 2>&1)
}

bundle_of() {
  find "$1/dist/assets" -maxdepth 1 -name '*.js' 2>/dev/null | head -1
}

step 1 "环境健康 + 内嵌最小 vue 工程（node/npm；vue/vite 由 app/ 安装）"
node -v
npm -v
if install_app "$APP"; then
  vuev="$(node -e "console.log(require('$APP/node_modules/vue/package.json').version)")"
  vitev="$(node -e "console.log(require('$APP/node_modules/vite/package.json').version)")"
  ok
  echo "  (vue@$vuev vite@$vitev —— 版本写入 WALKTHROUGH verified_env；registry 不可达时"
  echo "   本步失败，属环境问题，按 WALKTHROUGH 停止条件交维护者)"
else
  bad "npm install 失败（容器需可访问 npm registry）"
fi

step 2 "headless 挂载真跑：解构 props 丢响应性（Vue 运行时观测）"
out="$(cd "$APP" && node src/props-repro.mjs 2>&1)"
rc=$?
printf '%s\n' "$out"
if [ "$rc" -eq 1 ] && grep -q 'REACTIVITY-LOST' <<<"$out" && grep -q 'update renders Bug=2 Good=2 text buggy=1 good=2' <<<"$out"; then
  ok
  echo "  (Bug 与 Good 都重渲染了（Bug=2 Good=2），但 Bug 渲染出的文本仍是 1——组件确实更新了，"
  echo "   读的却是 setup 时刻解构出来的快照；Good 直读 props.count 拿到 2)"
else
  bad "应退出 1 且命中丢响应性证据行；实际 rc=$rc"
fi

step 3 "reactivity effect 隔离：代理读被追踪、解构快照读不被追踪"
out="$(cd "$APP" && node src/effect-isolate.mjs 2>&1)"
rc=$?
printf '%s\n' "$out"
if [ "$rc" -eq 1 ] && grep -q 'EFFECT proxy-read=2 destructured-read=1' <<<"$out"; then
  ok
  echo "  (把现象下沉到响应式原语层：同一个 reactive 对象，effect 只追踪经代理的读取；"
  echo "   解构在 setup 时刻完成一次属性读取，之后 effect 与它再无依赖关系)"
else
  bad "effect 隔离应命中 EFFECT proxy-read=2 destructured-read=1 且 rc=1；实际 rc=$rc"
fi

step 4 "vite build（未声明 env）：产物静态 grep void 0"
rm -rf "$APP/dist"
if (cd "$APP" && npx vite build >/dev/null 2>&1) && [ -n "$(bundle_of "$APP")" ]; then
  bundle="$(bundle_of "$APP")"
  void0="$(grep -o 'void 0' "$bundle" | wc -l | tr -d ' ')"
  hashname="$(basename "$bundle" | sed -E 's/index-[A-Za-z0-9_-]+\.js/index-HASH.js/')"
  echo "  ENV-VOID0-COUNT=$void0 (undeclared env, bundle: $hashname)"
  grep -o '.\{0,24\}void 0.\{0,12\}' "$bundle" | head -2 | sed 's/^/  | /'
  if [ "${void0:-0}" -ge 1 ]; then
    ok
    echo "  (import.meta.env.VITE_API_URL 被静态替换为 undefined，压缩后即 void 0——"
    echo "   「构建成功、零告警」不等于「配置在场」，产物级 grep 才看得见)"
  else
    bad "产物未命中 void 0（vite 版本漂移？登记 UNVERIFIED）"
  fi
else
  bad "vite build 失败或无产物"
fi

step 5 "修复对照 A：声明 env（写 .env.production）后 rebuild"
printf 'VITE_API_URL=https://api.example.dev\nVITE_BUILD_TAG=lab-demo\n' >"$APP/.env.production"
if (cd "$APP" && npx vite build >/dev/null 2>&1) && [ -n "$(bundle_of "$APP")" ]; then
  bundle="$(bundle_of "$APP")"
  void0="$(grep -o 'void 0' "$bundle" | wc -l | tr -d ' ')"
  inline="$(grep -o 'https://api.example.dev' "$bundle" | head -1)"
  echo "  ENV-VOID0-AFTER=$void0"
  echo "  ENV-INLINED: API_URL=${inline:-缺失}"
  if [ "${void0:-0}" -eq 0 ] && [ "$inline" = "https://api.example.dev" ]; then
    ok
    echo "  (声明的变量被字面内联进产物、void 0 归零——修复验证凭这两条产物级证据，"
    echo "   不是凭「构建没报错」)"
  else
    bad "声明后 void 0 应归零且字符串应内联；实际 void0=${void0:-缺失} inline=${inline:-缺失}"
  fi
else
  bad "rebuild 失败或无产物"
fi

step 6 "修复对照 B：不解构 props（sed 补丁副本真跑，REACTIVITY-OK）"
install_app "$FIX"
sed -e 's|const { count } = props; // 缺陷.*$|/* 修复：不解构，渲染时直读 props.count（活的响应式代理） */|' \
  -e 's|String(count)|String(props.count)|' \
  app/src/props-repro.mjs >"$FIX/src/props-repro.mjs"
out="$(cd "$FIX" && node src/props-repro.mjs 2>&1)"
rc=$?
printf '%s\n' "$out"
if [ "$rc" -eq 0 ] && grep -q 'REACTIVITY-OK' <<<"$out" && grep -q 'update renders Bug=2 Good=2 text buggy=2 good=2' <<<"$out"; then
  ok
  echo "  (同一运行时、同一数据流，唯一改动是渲染闭包直读 props.count——buggy 文本跟上更新，"
  echo "   退出码转 0。修复必须落在「渲染时读代理」，光删解构语句不留神渲染闭包也没用)"
else
  bad "修复副本应退出 0 且 REACTIVITY-OK；实际 rc=$rc"
fi

echo
if [ "$pass" -eq "$total" ]; then
  echo "RUN-PASS：$total/$total 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/$total 判定符合预期" >&2
exit 1
