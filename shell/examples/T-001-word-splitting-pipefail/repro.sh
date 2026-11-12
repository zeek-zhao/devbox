#!/usr/bin/env bash
# T-001-word-splitting-pipefail 最小复现：直跑缺陷脚本一次，稳定触发两类故障。
# 按 docs/72 §2 样板约定：复现成功 = 故障被触发 = 本脚本以非零退出码结束
# （缺陷脚本最后一条 wc 因分词拿到不存在的文件而 rc=1，诊断输出原样透传，
# 由调用方归一化后再断言）。用法：bash repro.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

bash bug.sh 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "repro: 故障未被触发（缺陷脚本竟退出 0，环境异常，见 WALKTHROUGH 决策树 Q0 分支）" >&2
  exit 3
fi
exit "$rc"
