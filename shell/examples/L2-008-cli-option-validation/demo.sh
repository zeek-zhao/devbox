#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' 'usage: demo.sh [-a] [-b value]' >&2
}

enabled=false
value=''
while getopts ':ab:' option; do
  case "$option" in
    a) enabled=true ;;
    b) value="$OPTARG" ;;
    :) usage; exit 2 ;;
    \?) usage; exit 2 ;;
  esac
done
shift "$((OPTIND - 1))"
if [ "$#" -ne 0 ]; then
  usage
  exit 2
fi

printf 'options: a=%s b=%s\n' "$enabled" "$value"
