#!/usr/bin/env bash
# T-001-deadlock-oom 断言：关键诊断行命中 + 退出码符合预期 + 不稳定输出归一化。
# docs/72 §2 样板扩展版：两段断言——最小复现（OOM + jcmd 死锁闭环）与完整演练。
# 用法：bash assert.sh ；连跑两次结论必须一致；退出非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

# ---- 第 1 段：最小复现。按 docs/72 真本：故障被触发 = 非零退出码。
out="$(bash repro.sh 2>&1)"
rc=$?
grep -q 'java.lang.OutOfMemoryError' <<<"$out" ||
  {
    echo "[assert] 未命中 OOM 诊断行（java.lang.OutOfMemoryError）"
    fail=1
  }
grep -q 'Found one Java-level deadlock' <<<"$out" ||
  {
    echo "[assert] 未命中 jcmd 死锁闭环行（Found one Java-level deadlock）"
    fail=1
  }
[ "$rc" -ne 0 ] || {
  echo "[assert] 预期非零退出码，实际 0（故障未被触发）"
  fail=1
}

# ---- 第 2 段：完整演练。run.sh 内部已做逐步判定，全过 = 退出 0。
tout="$(bash run.sh 2>&1)"
trc=$?
[ "$trc" -eq 0 ] || {
  echo "[assert] run.sh 应全绿退出 0，实际 $trc"
  tail -20 <<<"$tout" >&2
  fail=1
}
grep -q 'Exception in thread "main" java.lang.OutOfMemoryError' <<<"$tout" ||
  {
    echo "[assert] 未命中 OOM 原文行（Exception in thread \"main\" java.lang.OutOfMemoryError）"
    fail=1
  }
grep -q 'deadlock: start' <<<"$tout" ||
  {
    echo "[assert] 未命中执行标记行 deadlock: start（进程可能未被真正执行，素材 S-06）"
    fail=1
  }
grep -q 'Found one Java-level deadlock' <<<"$tout" ||
  {
    echo "[assert] 未命中 jcmd 死锁闭环行"
    fail=1
  }
grep -q 'which is held by' <<<"$tout" ||
  {
    echo "[assert] 未命中互等闭环描述行（which is held by）"
    fail=1
  }
grep -q '"worker-1"' <<<"$tout" ||
  {
    echo "[assert] 未命中死锁线程名 worker-1"
    fail=1
  }
grep -q '%CPU=' <<<"$tout" ||
  {
    echo "[assert] 未命中 top CPU 对照行（%CPU=）"
    fail=1
  }

# ---- 归一化后复断言：锁地址/nid/线程编号 → 占位符，禁止逐字比对整段输出。
norm="$(sed -E 's/0x[0-9a-f]+/0xADDR/g; s/#[0-9]+ /#N /g' <<<"$out")"
grep -q 'waiting to lock monitor 0xADDR' <<<"$norm" ||
  {
    echo "[assert] 归一化后未命中 waiting to lock 0xADDR（锁地址证据缺失，应为 waiting to lock monitor 0xADDR）"
    fail=1
  }
[ -n "$norm" ] || fail=1

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
