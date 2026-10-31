#!/usr/bin/env bash
set -euo pipefail

route() {
  case "$1" in
    start|run)
      printf 'action: start\n'
      ;;
    stop)
      printf 'action: stop\n'
      ;;
    *)
      printf 'action: unknown rejected\n'
      return 2
      ;;
  esac
}

route start
if route mystery; then
  printf 'unknown input accepted\n'
else
  printf 'unknown input status: nonzero\n'
fi
