#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: demo.sh deploy\n' >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

case "$1" in
  deploy)
    printf 'action=deploy\n'
    ;;
  *)
    usage
    exit 2
    ;;
esac
