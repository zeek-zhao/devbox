#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-014-custom-signal-ipc.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK" >"$WORK/out" &
demo_pid=$!

for _ in $(seq 1 100); do
  [[ -f "$WORK/ready" ]] && break
  sleep 0.05
done
[[ -f "$WORK/ready" ]]

send_until() { # $1=signal $2=目标次数 $3=计数控文件
  local want="$2" file="$3" n=0
  while :; do
    n="$(wc -l <"$file")"
    [[ "$n" -ge "$want" ]] && break
    kill -"$1" "$demo_pid"
    sleep 0.05
  done
}

send_until USR1 3 "$WORK/usr1.count"
send_until USR2 2 "$WORK/usr2.count"

touch "$WORK/stop"
wait "$demo_pid"
[[ "$(cat "$WORK/out")" == 'signals=usr1-3 usr2-2' ]]
printf 'signals=usr1-3 usr2-2\n'
