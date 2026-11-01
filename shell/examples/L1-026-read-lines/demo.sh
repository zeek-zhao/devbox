#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' '  leading space' 'path\to\file  ' |
  while IFS= read -r line; do
    printf 'line=[%s]\n' "$line"
  done
