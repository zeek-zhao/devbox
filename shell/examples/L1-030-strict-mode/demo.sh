#!/usr/bin/env bash
set -euo pipefail

work=$1
printf 'present\n' > "$work/input.txt"

if grep -q absent "$work/input.txt"; then
  printf 'expected miss handled: false\n'
else
  printf 'expected miss handled: true\n'
fi

if bash -c 'set -euo pipefail; false; printf "unreachable\n"' 2>"$work/failure.err"; then
  printf 'unhandled failure stops script: false\n'
else
  printf 'unhandled failure stops script: true\n'
fi

if bash -c 'set -euo pipefail; printf "%s\n" "$UNDEFINED_VALUE"' 2>"$work/undefined.err"; then
  printf 'undefined variable rejected: false\n'
else
  printf 'undefined variable rejected: true\n'
fi
