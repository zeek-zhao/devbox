#!/usr/bin/env bash
set -euo pipefail

value=parent
before="$(pwd)"
captured="$(cd / && value=child && printf '%s\n\n' "$value")"
after="$(pwd)"

printf 'captured=%s\n' "$captured"
printf 'parent_value=%s\n' "$value"
if [[ "$before" == "$after" ]]; then
  printf 'parent_directory=unchanged\n'
else
  printf 'parent_directory=changed\n'
fi
