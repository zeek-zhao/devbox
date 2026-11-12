#!/usr/bin/env bash
# 进程替换与命名管道：给只认文件路径的工具接上动态数据流的两种办法。
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-012-proc-substitution-fifo.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

diff <(printf 'x\ny\n') <(printf 'x\ny\n') >"$WORK/diff.out"
[[ ! -s "$WORK/diff.out" ]]

mkfifo "$WORK/pipe"
(printf 'hello\n' >"$WORK/pipe") &
writer=$!
line="$(cat <"$WORK/pipe")"
wait "$writer"
[[ "$line" == hello ]]
printf 'procsub=diff-clean fifo=handoff-ok\n'
