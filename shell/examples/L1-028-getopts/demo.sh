#!/usr/bin/env bash
set -euo pipefail

parse_options() {
  local OPTIND=1 option
  enabled=false
  value=''
  while getopts ':ab:' option; do
    case "$option" in
      a) enabled=true ;;
      b) value=$OPTARG ;;
      :) printf 'missing value for -%s\n' "$OPTARG"; return 1 ;;
      \?) printf 'invalid option: -%s\n' "$OPTARG"; return 1 ;;
    esac
  done
}

parse_options -a -b 'two words'
printf 'option -a enabled: %s\n' "$enabled"
printf 'option -b value: %s\n' "$value"

if parse_options -b; then
  printf 'missing value rejected: false\n'
else
  printf 'missing value rejected: true\n'
fi

if parse_options -z; then
  printf 'invalid option rejected: false\n'
else
  printf 'invalid option rejected: true\n'
fi
