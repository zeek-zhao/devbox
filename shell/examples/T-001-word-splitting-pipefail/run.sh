#!/usr/bin/env bash
# T-001-word-splitting-pipefail 演练入口：shellcheck → false|true 对照实验 →
# 缺陷脚本直跑 → bash -x 追踪分词 → pipefail 对照重跑，五步串完整流程。
# 工具（shellcheck 0.9 / bash 5.2，均预装在 devbox-shell 镜像里）请在容器内运行，例如：
#   docker run --rm -v "$PWD":/w -w /w \
#     ghcr.io/zeek-zhao/devbox-shell:latest bash shell/examples/T-001-word-splitting-pipefail/run.sh
# 产物只写临时目录，不入库。用法：bash run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

BUILD="${TMPDIR:-/tmp}/devbox-shell-T-001-word-splitting-pipefail"
FIXTURE="${TMPDIR:-/tmp}/devbox-shell-T-001-fixture"
mkdir -p "$BUILD"
# 输出归一化：临时目录路径在宿主/容器间可能不同，展示前打成占位符（docs/72 §2）。
norm() { sed -E "s#${TMPDIR:-/tmp}#/TMP#g"; }

pass=0
step() {
  echo
  echo "=== [step $1] $2 ==="
}
ok() {
  echo "  -> 符合预期"
  pass=$((pass + 1))
}
bad() { echo "  -> 不符合预期：$1" >&2; }

step 1 "shellcheck（静态分析器）：SC2086 把分词缺陷钉到具体行"
sclog="$BUILD/shellcheck.log"
if shellcheck -f gcc bug.sh >"$sclog" 2>&1; then
  bad "缺陷脚本应被 shellcheck（默认 severity）命中，实际退出 0"
else
  sc2086="$(grep -c 'SC2086' "$sclog" || true)"
  grep -E 'SC2086|SC2126' "$sclog" | sed 's/^/  | /'
  if [ "$sc2086" -ge 1 ]; then
    ok
    echo "  (SC2086 共 $sc2086 处，全在 \$target 展开点。注意：仓库门禁用 -S warning 时"
    echo "   这条是 info 级、不触发——静态门禁的 severity 阈值决定它能看见什么，素材 S-07)"
  else
    bad "未命中 SC2086（shellcheck 版本或行为漂移）"
  fi
fi

step 2 "对照实验（bash 运行时）：false|true 的退出码在 pipefail 开关两侧不同"
plain_rc="$(
  bash -c 'false | true'
  echo $?
)"
pf_rc="$(
  bash -o pipefail -c 'false | true'
  echo $?
)"
echo "  | 对照实验: false|true → rc=$plain_rc（plain：右侧成功掩盖左侧失败）"
echo "  | 对照实验: pipefail 开启 → rc=$pf_rc（管道取最右侧非零退出码）"
if [ "$plain_rc" -eq 0 ] && [ "$pf_rc" -eq 1 ]; then
  ok
else
  bad "应得 plain rc=0 / pipefail rc=1，实际 plain=$plain_rc pipefail=$pf_rc"
fi

step 3 "直跑缺陷脚本：两类症状同框（吞错的 rc=0 + 分词的 No such file）"
out="$(bash bug.sh 2>&1)"
rc=$?
echo "$out" | norm | sed 's/^/  | /'
if [ "$rc" -eq 1 ] && grep -q 'split: start' <<<"$out" &&
  grep -q 'matched=0 rc=0' <<<"$out" &&
  grep -q 'No such file or directory' <<<"$out"; then
  ok
  echo "  (rc=1 来自最后一条 wc：分词后两个参数都不存在；而上面 matched=0 rc=0 说明"
  echo "   管道左侧的失败已被吞——同一个脚本里两种「看不见的错」形态各异)"
else
  bad "应退出 1 且同时命中标记行 / matched=0 rc=0 / No such file；实际 rc=$rc"
fi

step 4 "bash -x 追踪：亲眼看分词发生在哪一步"
tlog="$BUILD/trace.log"
target="$FIXTURE/report final.txt" bash -x -c 'wc -l $target' >"$tlog" 2>&1 || true
grep '^+ wc' "$tlog" | norm | sed 's/^/  | /'
nargs="$(grep '^+ wc' "$tlog" | head -1 | awk '{print NF - 3}')"
if [ "$nargs" -eq 2 ]; then
  ok
  echo "  (写代码时是一个变量 \$target，展开后 wc 收到 2 个参数——分词不是玄学，"
  echo "   -x 追踪里白纸黑字)"
else
  bad "-x 追踪里 wc 应收到 2 个参数，实际 $nargs"
fi

step 5 "pipefail 对照重跑：同一条管道，开了 pipefail 立刻现形"
pplain="$(
  bash -c 'grep -c alpha "$1" 2>/dev/null | wc -l >/dev/null' bash "$FIXTURE/missing-deploy.log"
  echo $?
)"
ppf="$(
  bash -o pipefail -c 'grep -c alpha "$1" 2>/dev/null | wc -l >/dev/null' bash "$FIXTURE/missing-deploy.log"
  echo $?
)"
echo "  | pipefail 对照: 同一条管道 plain → rc=$pplain（吞掉）"
echo "  | pipefail 对照: pipefail → rc=$ppf（左侧 grep 因文件不存在 rc=2）"
if [ "$pplain" -eq 0 ] && [ "$ppf" -eq 2 ]; then
  ok
  echo "  (修复方向即此：在脚本头部加 set -o pipefail，让管道失败再也藏不住)"
else
  bad "应得 plain rc=0 / pipefail rc=2，实际 plain=$pplain pipefail=$ppf"
fi

echo
if [ "$pass" -eq 5 ]; then
  echo "RUN-PASS：5/5 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/5 判定符合预期" >&2
exit 1
