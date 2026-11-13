#!/usr/bin/env bash
# 读者路径完整性检查（#395 · M13-CONTENT-02）
#
# 模拟一个刚 clone 仓库的新读者，走完「找到第一个例子 → 跑通」的最短路径，
# 逐步计时并打印。任何一步失败即 exit 1（路径断了就是断了）。
# 慢**不设阈值**：只输出耗时基线，供 D-8 采集。
# 用法：bash scripts/check-reader-path.sh [--lang <lang>] [--example <E-ID>]
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

LANG=go
EXAMPLE=E-001-error-taxonomy
while [ $# -gt 0 ]; do
  case "$1" in
    --lang)
      LANG="$2"
      shift 2
      ;;
    --example)
      EXAMPLE="$2"
      shift 2
      ;;
    *)
      echo "未知参数：$1" >&2
      exit 2
      ;;
  esac
done

step_no=0
step_fail=0
step() {
  local name="$1"
  shift
  step_no=$((step_no + 1))
  local start end ms
  start="$(date +%s%N)"
  if "$@" >/tmp/reader-path-step.log 2>&1; then
    end="$(date +%s%N)"
    ms=$(((end - start) / 1000000))
    printf '[ok]   %-2d %-36s %6d ms\n' "$step_no" "$name" "$ms"
  else
    end="$(date +%s%N)"
    ms=$(((end - start) / 1000000))
    printf '[fail] %-2d %-36s %6d ms\n' "$step_no" "$name" "$ms"
    tail -10 /tmp/reader-path-step.log | sed 's/^/         /'
    step_fail=$((step_fail + 1))
    return 1
  fi
}

# 1. 仓库根有一句话入口（README 存在且能读）
step "读根 README" test -s README.md
# 2. 该轨有文档入口（读者知道自己该看哪）：docs/INDEX.md 或 知识点清单.md
step "轨内文档入口存在" bash -c "test -s '$LANG/docs/INDEX.md' -o -s '$LANG/docs/知识点清单.md'"
# 3. 例子目录存在，且三件套齐全（run.sh / expected.txt / README.md）
step "例子三件套齐全" test -f "$LANG/examples/$EXAMPLE/run.sh" -a -f "$LANG/examples/$EXAMPLE/expected.txt" -a -f "$LANG/examples/$EXAMPLE/README.md"
# 4. README 里写了复现命令（且能被 grep 到）
step "例子 README 有复现命令" grep -qE 'run-example\.sh|docker run' "$LANG/examples/$EXAMPLE/README.md"
# 5. 该轨文档里能查到该 ID（读者从知识点清单/INDEX/README 任一入口点进来）
step "轨内文档可检索到该 ID" bash -c "grep -rqF -- '$EXAMPLE' '$LANG/docs' '$LANG/README.md'"
# 6. 真跑该例子（中央 runner，含镜像）
step "run-example.sh 跑通" bash scripts/run-example.sh "$LANG" "$EXAMPLE"
# 7. 期望输出可读（读者能自己对照）
step "expected.txt 非空" test -s "$LANG/examples/$EXAMPLE/expected.txt"

printf '\n读者路径：%d 步，失败 %d 步\n' "$step_no" "$step_fail"
[ "$step_fail" -eq 0 ]
