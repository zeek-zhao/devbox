#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
work="$1"
cd "$work" || exit 1
: >sample-a.txt
: >sample-b.txt

show_args() {
  printf 'argument=%s\n' "$@"
}

value='two words *.txt'
printf 'unquoted:\n'
show_args $value
printf 'quoted:\n'
show_args "$value"
