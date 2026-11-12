#!/usr/bin/env bash
# xargs -P 并行与 -I 占位符：并行完成后必须收集、排序才能得到稳定输出。
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-011-xargs-parallel-placeholder.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

printf 'alpha\nbeta\ngamma\n' | xargs -P 2 -I{} bash -c 'printf "item {}\n"' >"$WORK/raw"
count="$(wc -l <"$WORK/raw")"
[[ "$count" -eq 3 ]]

sorted="$(sort "$WORK/raw" | tr '\n' ' ' | sed 's/ $//')"
[[ "$sorted" == 'item alpha item beta item gamma' ]]
printf 'xargs=parallel-3 sorted-stable\n'
