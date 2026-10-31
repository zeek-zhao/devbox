#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-006-signal-cleanup.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
export WORK

bash demo.sh worker &
worker_pid="$!"

# 有界握手：等待 worker 写出 ready 标记，最多 5 秒；这是启动确认，不是估时等待。
for _ in $(seq 1 100); do
  [[ -f "$WORK/ready" ]] && break
  sleep 0.05
done
[[ -f "$WORK/ready" ]] || { printf 'worker 未就绪\n' >&2; exit 1; }

kill -TERM "$worker_pid"
if wait "$worker_pid"; then
  printf 'worker: unexpectedly exited normally\n' >&2
  exit 1
fi

[[ ! -e "$WORK/active" ]]
[[ ! -e "$WORK/deployed" ]]
printf 'cleanup: verified\n'
printf 'deploy: skipped\n'
