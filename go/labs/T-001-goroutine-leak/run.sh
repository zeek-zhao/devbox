#!/usr/bin/env bash
# T-001-goroutine-leak 演练入口：go vet → plain 直跑（NumGoroutine 对照）→ -race →
# debug=2 栈快照 → go tool pprof 聚合画像，五步串完整流程。
# 工具（go 1.27 自带 -race、runtime/pprof、go tool pprof）预装在 devbox-go 镜像里，
# 请在容器内运行，例如：
#   docker run --rm -v "$PWD":/w -w /w \
#     ghcr.io/zeek-zhao/devbox-go:latest bash go/labs/T-001-goroutine-leak/run.sh
# 产物只写临时目录，不入库。用法：bash run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

GO="${GO:-go}"
BUILD="${TMPDIR:-/tmp}/devbox-go-T-001-goroutine-leak"
PLAIN="$BUILD/buggy-leak"
RACE="$BUILD/buggy-leak-race"
mkdir -p "$BUILD"
# 输出归一化：0x 地址与 goroutine 编号在两次运行间必然不同，展示前先打成占位符（docs/72 §2）。
norm() { sed -E 's/0x[0-9a-f]+/0xADDR/g; s/goroutine [0-9]+/goroutine G/g'; }

pass=0
step() { echo; echo "=== [step $1] $2 ==="; }
ok()  { echo "  -> 符合预期"; pass=$((pass+1)); }
bad() { echo "  -> 不符合预期：$1" >&2; }

step 1 "go vet（健康对照）：静态检查全绿，两个缺陷照样在场"
vetlog="$BUILD/vet.log"
if "$GO" vet ./... >"$vetlog" 2>&1; then
  ok
  echo "  (vet 退出 0、无任何告警——静态检查对运行时缺陷天然失明（素材 S-07："
  echo "   CI 全绿 ≠ 教学质量达标）。别把 vet 绿当结案证据)"
else
  bad "vet 应退出 0（缺陷不在静态检查射程内）；实际报错："
  sed 's/^/  | /' "$vetlog"
fi

step 2 "plain 构建直跑：runtime.NumGoroutine 前后对照坐实泄漏"
"$GO" build -buildvcs=false -o "$PLAIN" . || { echo "编译失败" >&2; exit 2; }
out="$("$PLAIN" 2>&1)"; rc=$?
echo "$out"
delta="$(sed -nE 's/.*delta=([0-9]+).*/\1/p' <<<"$out" | head -1)"
if [ "$rc" -eq 1 ] && grep -q 'leak: start' <<<"$out" && [ -n "$delta" ] && [ "$delta" -ge 90 ]; then
  ok
  echo "  (标记行 leak: start 证明二进制真的被跑过（素材 S-06）；delta=$delta 个 goroutine"
  echo "   在请求高峰后仍活着且不回落——若程序没有 NumGoroutine 自检，这一缺陷对外完全静默)"
else
  bad "应退出 1 且 delta>=90；实际 rc=$rc delta=${delta:-缺失}（见 WALKTHROUGH 决策树 Q0）"
fi

step 3 "-race 构建：把数据竞争钉到具体行"
"$GO" build -buildvcs=false -race -o "$RACE" . || { echo "编译失败" >&2; exit 2; }
rlog="$BUILD/race.log"
"$RACE" >"$rlog" 2>&1
rrc=$?
grep -E 'WARNING: DATA RACE|Read at 0x|Previous write at 0x|handleRequest|created at|Found [0-9]+ data race' \
  "$rlog" | head -12 | norm | sed 's/^/  | /'
if grep -q 'WARNING: DATA RACE' "$rlog" && [ "$rrc" -ne 0 ]; then
  ok
  echo "  (-race 把读写两份调用栈都钉到 counter++ 那一行。注意：泄漏与竞争是两个独立缺陷，"
  echo "   互相不掩盖也互不背锅——修掉竞争泄漏仍在，见 WALKTHROUGH 被否决假设 H2)"
else
  bad "-race 应报 WARNING: DATA RACE 且非零退出；实际 rc=$rrc"
fi

step 4 "debug=2 栈快照：每个泄漏 goroutine 都停泊在 [chan send]"
dlog="$BUILD/dump.log"
LEAK_DUMP=1 "$PLAIN" >"$dlog" 2>&1
chan="$(grep -c '\[chan send\]' "$dlog" || true)"
sed -n '/\[chan send\]/{p;q}' "$dlog" | norm | sed 's/^/  | /'
if [ "$chan" -ge 90 ]; then
  ok
  echo "  ([chan send] 停泊状态共 $chan 个：发到一个全程无人接收的无缓冲 channel，"
  echo "   这就是「goroutine 泄漏」在栈快照里的指纹)"
else
  bad "快照中 [chan send] 应 >=90 个，实际 $chan"
fi

step 5 "go tool pprof -top：泄漏聚合画像（main.handleRequest 累计样本 = 泄漏数）"
prof="$BUILD/gor.prof"
LEAK_PPROF="$prof" "$PLAIN" >"$BUILD/pprof-run.log" 2>&1
"$GO" tool pprof -top -nodecount=5 "$prof" >"$BUILD/pprof-top.log" 2>&1
sed -n '/Showing nodes accounting/,$p' "$BUILD/pprof-top.log" | sed 's/^/  | /'
cum="$(awk -v f=main.handleRequest '$NF==f {print $4; exit}' "$BUILD/pprof-top.log")"
if [ -n "$cum" ] && [ "$cum" -ge 90 ]; then
  ok
  echo "  (main.handleRequest 累计样本 cum=$cum：goroutine profile 里每个 goroutine 记一个样本，"
  echo "   累计值 ≈ 泄漏数——把「泄漏多少」从栈快照逐个数升级成一行统计)"
else
  bad "pprof -top 未在 main.handleRequest 行看到 >=90 的累计样本（实际 cum=${cum:-缺失}）"
fi

echo
if [ "$pass" -eq 5 ]; then
  echo "RUN-PASS：5/5 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/5 判定符合预期" >&2
exit 1
