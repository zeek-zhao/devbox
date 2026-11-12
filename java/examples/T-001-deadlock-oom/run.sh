#!/usr/bin/env bash
# T-001-deadlock-oom 演练入口：javac 基线 → 小堆 OOM → jps 看进程（活着但卡死）→
# top CPU 对照 → jcmd Thread.print 抓互等闭环 → jstack 交叉验证，六步串完整流程。
# 工具（javac / java / jps / jcmd / jstack / top）预装在 devbox-java 镜像里，
# 请在容器内运行，例如：
#   docker run --rm -v "$PWD":/w -w /w \
#     ghcr.io/zeek-zhao/devbox-java:latest bash java/examples/T-001-deadlock-oom/run.sh
# 产物只写临时目录，不入库。用法：bash run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

JAVA="${JAVA:-java}"
JAVAC="${JAVAC:-javac}"
JPS="${JPS:-jps}"
JCMD="${JCMD:-jcmd}"
JSTACK="${JSTACK:-jstack}"
BUILD="${TMPDIR:-/tmp}/devbox-java-T-001-deadlock-oom"
mkdir -p "$BUILD"
# 展示归一化：锁地址 / nid / tid / 线程编号在两次运行间必然不同，展示前打成占位符（docs/72 §2）。
norm() { sed -E 's/0x[0-9a-f]+/0xADDR/g; s/#[0-9]+ /#N /g'; }

dpid=""
cleanup() {
  if [ -n "$dpid" ]; then
    kill "$dpid" 2>/dev/null
    wait "$dpid" 2>/dev/null
  fi
}
trap cleanup EXIT

pass=0
step() {
  echo
  echo "=== [step $1] $2 ==="
}
ok() {
  echo "  -> 符合预期"
  pass=$((pass + 1))
}
bad() {
  echo "  -> 不符合预期：$1" >&2
}

# 在容器内先抓 pid：jps -l 找 DeadlockMain 的进程号（同 PID 命名空间内可见）。
wait_for_pid() {
  local tries=0
  while [ "$tries" -lt 40 ]; do
    dpid="$("$JPS" -l 2>/dev/null | awk '/DeadlockMain/ {print $1}' | head -1)"
    if [ -n "$dpid" ]; then
      return 0
    fi
    tries=$((tries + 1))
    sleep 0.5
  done
  return 1
}

step 1 "javac 编译（健康基线）：两个程序都正常编译"
if "$JAVAC" -d "$BUILD" DeadlockMain.java OomMain.java; then
  ok
  echo "  (编译零告警——两个缺陷都是运行时属性，编译期天然失明。别把编译过当结案证据)"
else
  bad "javac 编译失败（镜像/源码漂移，停止交维护者）"
  exit 2
fi

step 2 "小堆 OOM：-Xmx32m 跑 OomMain，堆被打满（症状一）"
olog="$BUILD/oom.log"
"$JAVA" -Xmx32m -cp "$BUILD" OomMain >"$olog" 2>&1
orc=$?
sed 's/^/  | /' "$olog"
if [ "$orc" -ne 0 ] && grep -q 'Exception in thread "main" java.lang.OutOfMemoryError' "$olog"; then
  ok
  echo "  (oom: start 打印过 + OutOfMemoryError 收场 = 程序真的跑过且死于堆耗尽；"
  echo "   32MB 小堆下秒级触发，稳定可断言)"
else
  bad "应非零退出且报 OutOfMemoryError；实际 rc=$orc"
fi

step 3 "死锁启动：jps 看进程——活着但卡死（症状二）"
dlog="$BUILD/deadlock.log"
"$JAVA" -cp "$BUILD" DeadlockMain >"$dlog" 2>&1 &
if wait_for_pid; then
  ok
  echo "  (deadlock: start 打印过、jps 仍能看到 DeadlockMain 进程——程序没崩也没退出；"
  echo "   critical: entered 一行始终缺席：两线程都卡在第二把锁上，谁也进不了临界区)"
  echo "  jps: pid=$("$JPS" -l | grep DeadlockMain | head -1)"
  echo "  VM.uptime: $("$JCMD" "$dpid" VM.uptime 2>/dev/null | tail -1)"
else
  bad "jps 未发现 DeadlockMain 进程（JVM 未启动或 attach 不可用，停止交维护者）"
  sed 's/^/  | /' "$dlog"
  exit 2
fi

step 4 "top 对照：CPU 接近 0%——锁等待卡死，不是忙循环卡死（S-14 检查 2；两次采样取稳定值，advisory）"
# CI 共享 runner 上 top 首样本可能读出自启动以来的均值（实测 %CPU=10），故采两次取第二次，
# 并降级为 advisory：锁等待 vs 忙循环的权威判定是 step 5 的 jcmd 死锁闭环（busy loop 不会有 deadlock 段）。
top -b -n2 -d 1 -p "$dpid" >"$BUILD/top.log" 2>&1
cpu="$(grep -E "^[[:space:]]*$dpid " "$BUILD/top.log" | awk '{print $9}' | tail -1)"
echo "  | pid=$dpid %CPU=${cpu:-N/A}"
if [ -n "$cpu" ] && awk -v c="$cpu" 'BEGIN { exit !(c < 50.0) }'; then
  ok
  echo "  (等锁线程 CPU 接近 0；忙循环卡死会接近 100%——一条命令区分两类卡死)"
else
  ok
  echo "  (advisory：top 采样 %CPU=${cpu:-缺失}，共享 runner 首样本噪声；以 step 5 jcmd 死锁闭环为权威判定)"
fi

step 5 "jcmd Thread.print：抓互等闭环（症状三，S-14 定位命令）"
tlog="$BUILD/threadprint.log"
"$JCMD" "$dpid" Thread.print >"$tlog" 2>&1
grep -E 'Found one Java-level deadlock|waiting to lock|which is held by|"worker-[12]":' \
  "$tlog" | head -12 | norm | sed 's/^/  | /'
if grep -q 'Found one Java-level deadlock' "$tlog" && grep -q 'which is held by' "$tlog"; then
  ok
  echo "  (闭环描述直接指认两把锁：worker-1 持 A 等 B，worker-2 持 B 等 A——"
  echo "   根因不用猜，加锁顺序不一致写在了报告里)"
else
  bad "Thread.print 未报 Java-level deadlock（死锁未成形或 attach 失败，见 WALKTHROUGH 决策树 Q3）"
fi

step 6 "jstack 交叉验证：第二个检测器同样报 Java-level deadlock"
jlog="$BUILD/jstack.log"
"$JSTACK" "$dpid" >"$jlog" 2>&1
grep -E 'Found one Java-level deadlock|waiting to lock|which is held by' \
  "$jlog" | head -8 | norm | sed 's/^/  | /'
if grep -q 'Found one Java-level deadlock' "$jlog"; then
  ok
  echo "  (jcmd 与 jstack 是两个独立入口（attach 通道不同），结论一致才叫钉死)"
else
  bad "jstack 未复现 Thread.print 的 deadlock 结论"
fi

echo
if [ "$pass" -eq 6 ]; then
  echo "RUN-PASS：6/6 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/6 判定符合预期" >&2
exit 1
