#!/usr/bin/env bash
set -euo pipefail

items=(one "two words")

show_items() {
  printf 'count=%s\n' "$#"
  for item in "$@"; do
    printf 'item=%s\n' "$item"
  done
}

printf '[@]\n'
show_items "${items[@]}"
printf '[*]\n'
show_items "${items[*]}"
