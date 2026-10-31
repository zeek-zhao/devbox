#!/usr/bin/env bash
set -euo pipefail

value="two words"

if [[ $value == "two words" ]]; then
  printf 'double brackets: exact match\n'
fi

if [[ $value =~ ^two ]]; then
  printf 'double brackets: regex match\n'
fi

if [ "$value" = "two words" ]; then
  printf 'single brackets: exact match\n'
fi
