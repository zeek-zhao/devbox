#!/usr/bin/env bash
set -euo pipefail

show_items() {
  local item
  for item in "$@"; do
    printf 'item: <%s>\n' "$item"
  done
}

items=("one two" "*.txt")
printf 'index 1: %s\n' "${items[1]}"
printf 'item count: %s\n' "${#items[@]}"
show_items "${items[@]}"
