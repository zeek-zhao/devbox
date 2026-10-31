#!/usr/bin/env bash
set -euo pipefail

value=parent

local_value() {
  local value=inner
  printf 'local_value=%s\n' "$value"
}

string_result() {
  printf 'result=completed\n'
}

status_result() {
  return 7
}

local_output="$(local_value)"
message="$(string_result)"
if status_result; then
  status=0
else
  status=$?
fi

printf '%s\n' "$local_output"
printf '%s\n' "$message"
printf 'parent_value=%s\n' "$value"
printf 'return_status=%s\n' "$status"
