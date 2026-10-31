#!/usr/bin/env bash
set -euo pipefail

work=$1
bash -c 'printf "stdout line\n"; printf "stderr line\n" >&2' >"$work/shared.log" 2>&1
if grep -qx 'stdout line' "$work/shared.log" && grep -qx 'stderr line' "$work/shared.log"; then
  printf 'stdout and stderr share file: true\n'
else
  printf 'stdout and stderr share file: false\n'
fi

captured_stderr=$(bash -c 'printf "stdout line\n"; printf "stderr line\n" >&2' 2>&1 >"$work/reversed.out")
printf 'reversed order captured stderr: %s\n' "$captured_stderr"
printf 'reversed order file: %s\n' "$(cat "$work/reversed.out")"
