#!/usr/bin/env bash
set -euo pipefail

value='red,blue'
IFS=,
set -- $value
printf 'comma-count=%s\n' "$#"
printf 'comma-field=%s\n' "$@"

IFS=$' \t\n'
value='left right'
set -- $value
printf 'space-count=%s\n' "$#"
printf 'space-field=%s\n' "$@"
