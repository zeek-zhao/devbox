#!/usr/bin/env bash
# T-001-props-reactivity-env 断言：关键诊断行命中 + 退出码符合预期 + 不稳定输出归一化。
# docs/72 §2 样板扩展版：两段断言——最小复现（repro.sh，退出码 1 = 证据坐实）
# 与完整演练（run.sh 全绿退出 0）。用法：bash assert.sh；连跑两次结论必须一致。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

# ---- 第 1 段：最小复现（挂载真跑 + effect 隔离 + 产物 void 0）。
out="$(bash repro.sh 2>&1)"
rc=$?
grep -q 'PROPS-REPRO start' <<<"$out" ||
  {
    echo "[assert] 未命中执行标记行 PROPS-REPRO start（脚本可能未被真正执行，素材 S-06）"
    fail=1
  }
grep -q 'update renders Bug=2 Good=2 text buggy=1 good=2' <<<"$out" ||
  {
    echo "[assert] 未命中更新后对照行（Bug 重渲染但仍读快照 buggy=1，Good=2）"
    fail=1
  }
grep -q 'REACTIVITY-LOST: Bug re-rendered 2x but its text froze at 1 while live props.count = 2' <<<"$out" ||
  {
    echo "[assert] 未命中丢响应性证据行（REACTIVITY-LOST: ... froze at 1 ... props.count = 2）"
    fail=1
  }
grep -q 'EFFECT proxy-read=2 destructured-read=1' <<<"$out" ||
  {
    echo "[assert] 未命中 effect 隔离对照行（EFFECT proxy-read=2 destructured-read=1）"
    fail=1
  }
void0="$(sed -nE 's/.*ENV-VOID0-COUNT=([0-9]+).*/\1/p' <<<"$out" | head -1)"
if [ -z "$void0" ] || [ "$void0" -lt 1 ]; then
  echo "[assert] 未命中产物 void 0 计数（ENV-VOID0-COUNT>=1，实际 ${void0:-缺失}）"
  fail=1
fi
grep -q 'const .*void 0' <<<"$out" ||
  {
    echo "[assert] 复现输出未见 void 0 内联上下文行（const ...=void 0）"
    fail=1
  }
[ "$rc" -ne 0 ] ||
  {
    echo "[assert] repro.sh 预期非零退出码（证据坐实纪律），实际 0"
    fail=1
  }

# ---- 第 2 段：完整演练（run.sh 内部已做逐步判定，全过 = 退出 0）。
tout="$(bash run.sh 2>&1)"
trc=$?
[ "$trc" -eq 0 ] || {
  echo "[assert] run.sh 应全绿退出 0，实际 $trc"
  tail -20 <<<"$tout" >&2
  fail=1
}
grep -q 'RUN-PASS' <<<"$tout" ||
  {
    echo "[assert] 未命中 run.sh 全绿标记（RUN-PASS：6/6）"
    fail=1
  }
grep -q 'ENV-VOID0-AFTER=0' <<<"$tout" ||
  {
    echo "[assert] 未命中修复对照 A（声明 env 后 void 0 归零）"
    fail=1
  }
grep -q 'ENV-INLINED: API_URL=https://api.example.dev' <<<"$tout" ||
  {
    echo "[assert] 未命中内联字符串证据行（ENV-INLINED: API_URL=...）"
    fail=1
  }
grep -q 'REACTIVITY-OK' <<<"$tout" ||
  {
    echo "[assert] 未命中修复对照 B（不解构 props → REACTIVITY-OK）"
    fail=1
  }
grep -q 'update renders Bug=2 Good=2 text buggy=2 good=2' <<<"$tout" ||
  {
    echo "[assert] 未命中修复后对照行（buggy=2 good=2）"
    fail=1
  }

# ---- 归一化后复断言：bundle 内容 hash / 构建耗时 → 占位符，禁止逐字比对整段输出。
norm="$(sed -E 's/index-[A-Za-z0-9_-]+\.js/index-HASH.js/g; s/built in [0-9]+ms/built in Nms/g' <<<"$out")"
grep -q 'bundle: index-HASH.js' <<<"$norm" ||
  {
    echo "[assert] 归一化后未命中 bundle 占位行（index-HASH.js）"
    fail=1
  }
grep -Eq 'ENV-VOID0-COUNT=[0-9]+ .undeclared env, bundle: index-HASH.js.' <<<"$norm" ||
  {
    echo "[assert] 归一化后未命中完整 void 0 计数行"
    fail=1
  }
[ -n "$norm" ] || fail=1

if [ "$fail" -eq 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
