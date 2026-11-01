#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$WORK/tree/one/two"
printf 'root\n' >"$WORK/tree/root.txt"
printf 'level one\n' >"$WORK/tree/one/level.txt"
printf 'deep\n' >"$WORK/tree/one/two/deep.txt"
printf 'hidden\n' >"$WORK/tree/.hidden.txt"

shopt -s globstar nullglob
files=("$WORK/tree"/**/*.txt)
if ((${#files[@]} == 0)); then
  printf 'matches: none\n'
else
  for file in "${files[@]}"; do
    printf '%s\n' "${file#"$WORK/tree"/}"
  done | sort
fi
