#!/usr/bin/env bash
# T-001-word-splitting-pipefail 断言：关键诊断行命中 + 退出码符合预期 + 不稳定输出归一化。
# docs/72 §2 样板扩展版：两段断言——最小复现（缺陷脚本直跑）与完整演练（shellcheck/pipefail 路径）。
# 用法：bash assert.sh ；连跑两次结论必须一致；退出非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

# ---- 第 1 段：最小复现。按 docs/72 真本：故障被触发 = 非零退出码。
out="$(bash repro.sh 2>&1)"
rc=$?
grep -q 'split: start' <<<"$out" ||
  {
    echo "[assert] 未命中执行标记行 split: start（脚本可能未被真正执行，素材 S-06）"
    fail=1
  }
grep -q 'matched=0 rc=0' <<<"$out" ||
  {
    echo "[assert] 未命中管道吞错证据行（matched=0 rc=0：grep 失败被 wc 吞掉）"
    fail=1
  }
grep -q 'No such file or directory' <<<"$out" ||
  {
    echo "[assert] 未命中分词症状行（No such file or directory）"
    fail=1
  }
[ "$rc" -ne 0 ] || {
  echo "[assert] 预期非零退出码，实际 0（分词故障未被触发）"
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
grep -q 'RUN-PASS' <<<"$tout" ||
  {
    echo "[assert] 未命中 run.sh 全绿标记（RUN-PASS：5/5）"
    fail=1
  }
grep -q 'SC2086' <<<"$tout" ||
  {
    echo "[assert] 未命中 shellcheck 诊断行（SC2086）"
    fail=1
  }
grep -q '对照实验: false|true → rc=0' <<<"$tout" ||
  {
    echo "[assert] 未命中对照实验 plain 行（false|true → rc=0）"
    fail=1
  }
grep -q 'pipefail 开启 → rc=1' <<<"$tout" ||
  {
    echo "[assert] 未命中对照实验 pipefail 行（pipefail 开启 → rc=1）"
    fail=1
  }
grep -q 'pipefail 对照: pipefail → rc=2' <<<"$tout" ||
  {
    echo "[assert] 未命中真实管道 pipefail 对照行（rc=2）"
    fail=1
  }

# ---- 归一化后复断言：临时目录路径 / 退出码数字 → 占位符，禁止逐字比对整段输出。
norm="$(sed -E "s#${TMPDIR:-/tmp}#/TMP#g; s/rc=[0-9]+/rc=N/g; s/matched=[0-9]+/matched=N/g" <<<"$out")"
grep -q 'pipeline: matched=N rc=N' <<<"$norm" ||
  {
    echo "[assert] 归一化后未命中管道吞错证据行"
    fail=1
  }
grep -q 'wc: /TMP/devbox-shell-T-001-fixture/report: No such file or directory' <<<"$norm" ||
  {
    echo "[assert] 归一化后未命中分词症状行（路径被拆开的 wc 报错）"
    fail=1
  }
[ -n "$norm" ] || fail=1

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
