#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  report)
    printf 'result=ready\n'
    ;;
  reject)
    printf 'result=denied\n'
    exit 7
    ;;
  *)
    printf 'usage: demo.sh report|reject\n' >&2
    exit 2
    ;;
esac
