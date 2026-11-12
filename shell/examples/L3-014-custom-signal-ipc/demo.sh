#!/usr/bin/env bash
# worker：USR1/USR2 各自计数，收到 stop 文件后退出并汇总。
set -euo pipefail

WORK="$1"
COUNT1="$WORK/usr1.count"
COUNT2="$WORK/usr2.count"
: >"$COUNT1"
: >"$COUNT2"

handle1() { echo 1 >>"$COUNT1"; }
handle2() { echo 1 >>"$COUNT2"; }
trap handle1 USR1
trap handle2 USR2

echo ready >"$WORK/ready"
while [[ ! -f "$WORK/stop" ]]; do
  sleep 0.02
done

printf 'signals=usr1-%s usr2-%s\n' "$(wc -l <"$COUNT1")" "$(wc -l <"$COUNT2")"
