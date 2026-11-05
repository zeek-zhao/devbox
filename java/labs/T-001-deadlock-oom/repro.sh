#!/usr/bin/env bash
# T-001-deadlock-oom 最小复现：小堆 OOM 一次 + 两把锁反序死锁一次并用 jcmd 抓到互等闭环。
# 按 docs/72 §2 样板约定：复现成功 = 故障被触发 = 本脚本以非零退出码结束
# （OOM 的 OutOfMemoryError 与死锁的 Java-level deadlock 都是「故障在场」的证据）。
# 产物只写临时目录，不入库。用法：bash repro.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

JAVA="${JAVA:-java}"
JAVAC="${JAVAC:-javac}"
JPS="${JPS:-jps}"
JCMD="${JCMD:-jcmd}"
BUILD="${TMPDIR:-/tmp}/devbox-java-T-001-deadlock-oom"
mkdir -p "$BUILD"

dpid=""
cleanup() {
  if [ -n "$dpid" ]; then
    kill "$dpid" 2>/dev/null
    wait "$dpid" 2>/dev/null
  fi
}
trap cleanup EXIT

"$JAVAC" -d "$BUILD" DeadlockMain.java OomMain.java || {
  echo "repro: 编译失败" >&2
  exit 2
}

# 复现一：32MB 小堆必被无界分配打满，OutOfMemoryError 稳定出现。
"$JAVA" -Xmx32m -cp "$BUILD" OomMain 2>&1
orc=$?
if [ "$orc" -eq 0 ]; then
  echo "repro: OOM 竟退出 0，堆耗尽未被触发（环境异常，见 WALKTHROUGH 决策树）" >&2
  exit 3
fi

# 复现二：反序取锁，jcmd Thread.print 必报 Java-level deadlock（先抓 pid 再 attach）。
"$JAVA" -cp "$BUILD" DeadlockMain 2>&1 &
tries=0
while [ "$tries" -lt 40 ]; do
  dpid="$("$JPS" -l 2>/dev/null | awk '/DeadlockMain/ {print $1}' | head -1)"
  if [ -n "$dpid" ]; then
    break
  fi
  tries=$((tries + 1))
  sleep 0.5
done
if [ -z "$dpid" ]; then
  echo "repro: jps 未发现 DeadlockMain 进程（attach 不可用，停止交维护者）" >&2
  exit 2
fi
sleep 1
"$JCMD" "$dpid" Thread.print 2>&1 | grep -A8 'Found one Java-level deadlock'
if ! "$JCMD" "$dpid" Thread.print 2>/dev/null | grep -q 'Found one Java-level deadlock'; then
  echo "repro: Thread.print 未报 Java-level deadlock，死锁未成形（决策树 Q3 分支）" >&2
  exit 3
fi
# 故障被稳定触发：以非零退出码结束（docs/72 §2 约定）。
exit 1
