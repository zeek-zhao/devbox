#!/usr/bin/env bash
set -euo pipefail

work="$1"
mkdir -p "$work/tree/one/two"
touch "$work/tree/one/shallow.txt" "$work/tree/one/two/deep.txt"
if ! cd "$work"; then
  printf 'cannot enter work directory\n' >&2
  exit 1
fi

unmatched=( *.missing )
printf 'default unmatched count: %s\n' "${#unmatched[@]}"

shopt -s nullglob
unmatched=( *.missing )
printf 'nullglob unmatched count: %s\n' "${#unmatched[@]}"

shopt -s globstar
files=( tree/**/*.txt )
printf 'globstar matches:\n'
printf '  %s\n' "${files[@]}"
