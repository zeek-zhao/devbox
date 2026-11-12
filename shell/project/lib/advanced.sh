#!/usr/bin/env bash
# 毕业项目扩展能力（#396 补齐 L2-013..L2-020、L3-007..L3-015）。
# 每个函数对应一个 shell 用例，函数名统一 adv_ 前缀避免与主流程冲突。

# L2-013-log-level-filtering: 按级别过滤日志，error 恒走 stderr。
adv_log_emit() {
  local level=$1 msg=$2 logfile=$3
  case "$level" in
    debug) if [[ "${LOG_LEVEL:-info}" == debug ]]; then printf 'debug %s\n' "$msg" >>"$logfile"; fi ;;
    info) printf 'info %s\n' "$msg" >>"$logfile" ;;
    error)
      printf 'error %s\n' "$msg" >&2
      printf 'error %s\n' "$msg" >>"$logfile"
      ;;
    *) die "unknown log level: $level" ;;
  esac
}

# L2-014-config-allowlist-load: 只允许白名单键进入环境，其余整行拒绝。
adv_config_load() {
  local file=$1
  local -a allow=(DB_HOST DB_PORT LOG_LEVEL)
  local line key rejected='' allowed k
  while IFS= read -r line; do
    [[ "$line" == *=* && "$line" != '#'* ]] || continue
    key=${line%%=*}
    allowed=0
    for k in "${allow[@]}"; do
      if [[ "$key" == "$k" ]]; then
        allowed=1
        break
      fi
    done
    if [[ "$allowed" == 1 ]]; then
      export "${line%%=*}=${line#*=}"
    else
      rejected="$rejected $key"
    fi
  done <"$file"
  if [[ -n "$rejected" ]]; then printf 'rejected:%s\n' "$rejected" >&2; fi
  return 0
}

# L2-015-dry-run-plan-apply: 同一函数按模式输出计划或落盘，计划态绝不写。
adv_plan_apply() {
  local mode=$1 target=$2
  if [[ "$mode" == dry-run ]]; then
    printf 'PLAN touch %s\n' "$target"
  else
    : >"$target"
    printf 'APPLIED %s\n' "$target"
  fi
}

# L2-016-resume-state-marker: 步骤落盘到状态文件，重跑只补未完成步。
adv_resume_run() {
  local state=$1 fail_at=${2:-0}
  local i
  for i in 1 2 3; do
    grep -qx "step$i" "$state" 2>/dev/null && continue
    if [[ "$i" -eq "$fail_at" ]]; then
      return 1
    fi
    echo "step$i" >>"$state"
  done
}

# L2-017-path-hygiene-deps: 依赖前置检查，缺命令列出名字并退出非零。
adv_deps_check() {
  local missing=() cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    printf 'missing: %s\n' "${missing[*]}" >&2
    return 1
  fi
}

# L2-018-worker-pool-wait-n: N 个 worker 并行，wait 后逐个回收成败。
adv_worker_pool() {
  local total=$1 fail_at=$2
  local -a pids=()
  local i ok=0 failed=0
  for i in $(seq 1 "$total"); do
    (
      [[ "$i" -eq "$fail_at" ]] && exit 1
      sleep 0.05
      exit 0
    ) &
    pids+=("$!")
  done
  for i in "${!pids[@]}"; do
    wait "${pids[$i]}" && ok=$((ok + 1)) || failed=$((failed + 1))
  done
  printf 'pool=workers%d ok=%d failed=%d\n' "$total" "$ok" "$failed"
}

# L2-019-manifest-install-uninstall: 清单驱动安装与卸载，清单外内容不动。
adv_manifest_apply() {
  local mode=$1 root=$2
  shift 2
  local name n=0
  for name in "$@"; do
    if [[ "$mode" == install ]]; then
      mkdir -p "$root/pkgs"
      printf 'installed %s\n' "$name" >"$root/pkgs/$name"
    else
      rm -f "$root/pkgs/$name"
    fi
    n=$((n + 1))
  done
  printf '%s-%d\n' "$mode" "$n"
}

# L2-020-log-rotation-size: 写满限额轮转，保留最近 N 份历史。
adv_log_rotate() {
  local dir=$1 limit_bytes=$2 keep=$3 line=${4:-payload}
  mkdir -p "$dir"
  local log="$dir/app.log" size suffix
  while :; do
    if [[ -f "$log" ]]; then
      size="$(wc -c <"$log")"
    else
      size=0
    fi
    [[ "$size" -le "$limit_bytes" ]] || break
    printf '%s\n' "$line" >>"$log"
  done
  suffix=0
  local f
  for f in "$dir"/app.log.*; do [[ -e "$f" ]] && suffix=$((suffix + 1)); done
  mv "$log" "$dir/app.log.$suffix"
  local -a logs=() sorted
  for f in "$dir"/app.log.*; do [[ -e "$f" ]] && logs+=("$f"); done
  if ((${#logs[@]} > keep)); then
    mapfile -t sorted < <(printf '%s\n' "${logs[@]}" | sort -r)
    local idx=$((keep))
    for (( ; idx < ${#sorted[@]}; idx++)); do rm -f "${sorted[$idx]}"; done
  fi
}

# L3-007-process-group-setsid: 整组终止 setsid 会话，含孙进程。
adv_pgroup_terminate() {
  setsid bash -c 'sleep 60 & sleep 60 & wait' &
  local leader=$! pgid members remaining
  for _ in $(seq 1 50); do
    pgid="$(ps -o pgid= -p "$leader" 2>/dev/null | tr -d ' ')"
    if [[ -n "$pgid" ]]; then break; fi
    sleep 0.1
  done
  for _ in $(seq 1 50); do
    members="$(ps -eo pid=,pgid= 2>/dev/null | awk -v g="$pgid" '$2==g' | wc -l)"
    if [[ "$members" -ge 3 ]]; then break; fi
    sleep 0.1
  done
  kill -- -"$pgid"
  for _ in $(seq 1 50); do
    remaining="$(ps -eo pid=,pgid= 2>/dev/null | awk -v g="$pgid" '$2==g' | wc -l)"
    if [[ "$remaining" -eq 0 ]]; then break; fi
    sleep 0.1
  done
  [[ "$remaining" -eq 0 ]]
}

# L3-008-ulimit-resource-obs: -f 超限写触发 SIGXFSZ，文件截断在限额内。
adv_ulimit_probe() {
  local dir=$1 rc=0 size
  (
    ulimit -f 1
    head -c 5000 /dev/zero >"$dir/big"
  ) 2>/dev/null || rc=$?
  [[ "$rc" -eq 153 ]]
  size="$(wc -c <"$dir/big")"
  [[ "$size" -gt 0 && "$size" -le 1024 ]]
}

# L3-009-umask-file-perms: 077/022 掩码的新文件与新目录落点。
adv_umask_probe() {
  local dir=$1
  (
    umask 077
    : >"$dir/secret.txt"
    mkdir "$dir/secret.d"
  )
  (
    umask 022
    : >"$dir/public.txt"
    mkdir "$dir/public.d"
  )
  [[ "$(stat -c %a "$dir/secret.txt")" == 600 && "$(stat -c %a "$dir/secret.d")" == 700 ]]
  [[ "$(stat -c %a "$dir/public.txt")" == 644 && "$(stat -c %a "$dir/public.d")" == 755 ]]
}

# L3-010-symlink-handling: 链接解析、悬空检测与重链恢复。
adv_symlink_probe() {
  local dir=$1
  printf 'orig\n' >"$dir/target.conf"
  ln -s "$dir/target.conf" "$dir/link.conf"
  [[ -L "$dir/link.conf" && -f "$dir/link.conf" ]]
  [[ "$(readlink -f "$dir/link.conf")" == "$dir/target.conf" ]]
  rm "$dir/target.conf"
  [[ -L "$dir/link.conf" && ! -e "$dir/link.conf" ]]
  printf 'new\n' >"$dir/target.conf"
  [[ "$(cat "$dir/link.conf")" == new ]]
}

# L3-011-xargs-parallel-placeholder: 并行任务数固定，输出排序后稳定。
adv_xargs_parallel() {
  local dir=$1
  printf 'alpha\nbeta\ngamma\n' | xargs -P 2 -I{} bash -c 'printf "item {}\n"' >"$dir/raw"
  [[ "$(wc -l <"$dir/raw")" -eq 3 ]]
  [[ "$(sort "$dir/raw" | tr '\n' ' ' | sed 's/ $//')" == 'item alpha item beta item gamma' ]]
}

# L3-012-proc-substitution-fifo: 进程替换喂文件路径工具 + FIFO 交接。
adv_procsub_fifo() {
  local dir=$1 line
  diff <(printf 'x\ny\n') <(printf 'x\ny\n') >"$dir/diff.out"
  [[ ! -s "$dir/diff.out" ]]
  mkfifo "$dir/pipe"
  (printf 'hello\n' >"$dir/pipe") &
  local writer=$!
  line="$(cat <"$dir/pipe")"
  wait "$writer"
  [[ "$line" == hello ]]
}

# L3-013-atomic-counter-flock: 锁内读-改-写，并发增量不丢计数。
adv_flock_counter() {
  local dir=$1
  echo 0 >"$dir/counter"
  : >"$dir/lock"
  adv_bump() {
    local n=0
    while ((n < 20)); do
      (
        flock 9
        local c
        c="$(cat "$dir/counter")"
        echo $((c + 1)) >"$dir/counter"
      ) 9>"$dir/lock"
      n=$((n + 1))
    done
  }
  adv_bump &
  adv_bump
  wait
  [[ "$(cat "$dir/counter")" -eq 40 ]]
}

# L3-014-custom-signal-ipc: USR1/USR2 计数握手，发一条确认一条。
adv_signal_ipc() {
  local dir=$1 n
  bash -c '
    set -euo pipefail
    WORK="$1"; C1="$WORK/u1"; C2="$WORK/u2"; : >"$C1"; : >"$C2"
    t1() { echo 1 >>"$C1"; }
    t2() { echo 1 >>"$C2"; }
    trap t1 USR1; trap t2 USR2
    echo ready >"$WORK/ready"
    while [[ ! -f "$WORK/stop" ]]; do sleep 0.02; done
  ' _ "$dir" &
  local worker=$!
  for _ in $(seq 1 100); do
    if [[ -f "$dir/ready" ]]; then break; fi
    sleep 0.05
  done
  advance_signal() {
    local sig=$1 want=$2 file=$3
    while :; do
      n="$(wc -l <"$file")"
      if [[ "$n" -ge "$want" ]]; then break; fi
      kill -"$sig" "$worker"
      sleep 0.05
    done
  }
  advance_signal USR1 3 "$dir/u1"
  advance_signal USR2 2 "$dir/u2"
  touch "$dir/stop"
  wait "$worker"
  [[ "$(wc -l <"$dir/u1")" -eq 3 && "$(wc -l <"$dir/u2")" -eq 2 ]]
}

# L3-015-flavor-detection: 探测工具链口味并断言 GNU 写法。
adv_flavor_probe() {
  local flavor
  if date --version >/dev/null 2>&1; then
    flavor=gnu
  elif date 2>&1 | grep -q BusyBox; then
    flavor=busybox
  else
    flavor=unknown
  fi
  [[ "$flavor" == gnu ]]
  [[ -d "$(readlink -f /bin)" ]]
  local probe=$1
  printf 'before\n' >"$probe"
  sed -i 's/before/after/' "$probe"
  [[ "$(cat "$probe")" == after ]]
}

advanced_self_check() {
  local ws
  # shellcheck disable=SC2154  # workspace 由已 source 的 lib/common.sh new_workspace 赋值
  ws="$workspace"
  mkdir -p "$ws/pkgs"

  # L2-013-log-level-filtering
  adv_log_emit debug hidden "$ws/app.log"
  adv_log_emit info shown "$ws/app.log"
  adv_log_emit error always "$ws/app.log" 2>/dev/null
  [[ "$(grep -c '^info' "$ws/app.log")" -eq 1 ]]
  [[ "$(grep -c '^debug' "$ws/app.log" || true)" -eq 0 ]]
  [[ "$(grep -c '^error' "$ws/app.log")" -eq 1 ]]

  # L2-014-config-allowlist-load
  cat >"$ws/app.conf" <<'CONF'
DB_HOST=localhost
DB_PORT=5432
LOG_LEVEL=info
root_shell=/bin/bash
CONF
  adv_config_load "$ws/app.conf" 2>/dev/null
  [[ "${DB_PORT:-}" == 5432 && -z "${root_shell:-}" ]]

  # L2-015-dry-run-plan-apply
  adv_plan_apply dry-run "$ws/marker" | grep -qx 'PLAN touch .*marker'
  [[ ! -e "$ws/marker" ]]
  adv_plan_apply apply "$ws/marker" >/dev/null
  [[ -e "$ws/marker" ]]

  # L2-016-resume-state-marker
  : >"$ws/state"
  adv_resume_run "$ws/state" 2 >/dev/null || true
  [[ "$(grep -c . "$ws/state")" -eq 1 ]]
  adv_resume_run "$ws/state"
  [[ "$(grep -c . "$ws/state")" -eq 3 ]]

  # L2-017-path-hygiene-deps
  adv_deps_check bash awk

  # L2-018-worker-pool-wait-n
  adv_worker_pool 5 3 | grep -qx 'pool=workers5 ok=4 failed=1'

  # L2-019-manifest-install-uninstall
  [[ "$(adv_manifest_apply install "$ws" a b c)" == install-3 ]]
  [[ "$(adv_manifest_apply uninstall "$ws" a b)" == uninstall-2 ]]
  [[ -f "$ws/pkgs/c" && ! -e "$ws/pkgs/a" ]]

  # L2-020-log-rotation-size: 两次轮转产生两份历史，当前文件清空
  adv_log_rotate "$ws/rot" 64 2 x
  adv_log_rotate "$ws/rot" 64 2 x
  rot_hist=0
  for f in "$ws/rot"/app.log.*; do [[ -e "$f" ]] && rot_hist=$((rot_hist + 1)); done
  [[ "$rot_hist" -eq 2 ]]
  [[ ! -e "$ws/rot/app.log" ]]

  # L3-007-process-group-setsid
  adv_pgroup_terminate

  # L3-008-ulimit-resource-obs
  adv_ulimit_probe "$ws"

  # L3-009-umask-file-perms
  adv_umask_probe "$ws"

  # L3-010-symlink-handling
  adv_symlink_probe "$ws"

  # L3-011-xargs-parallel-placeholder
  adv_xargs_parallel "$ws"

  # L3-012-proc-substitution-fifo
  adv_procsub_fifo "$ws"

  # L3-013-atomic-counter-flock
  adv_flock_counter "$ws"

  # L3-014-custom-signal-ipc
  adv_signal_ipc "$ws"

  # L3-015-flavor-detection
  adv_flavor_probe "$ws/flavor.txt"

  printf 'advanced self-check OK\n'
}
