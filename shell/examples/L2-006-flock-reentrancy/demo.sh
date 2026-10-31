#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  hold)
    lock_file="$2"
    ready_pipe="$3"
    release_pipe="$4"
    exec 9>"$lock_file"
    flock -n 9
    printf 'locked\n' >"$ready_pipe"
    IFS= read -r _ <"$release_pipe"
    ;;
  compete)
    lock_file="$2"
    exec 9>"$lock_file"
    if flock -n 9; then
      printf 'acquired\n'
    else
      printf 'busy\n'
    fi
    ;;
  *)
    printf 'usage: demo.sh hold|compete ...\n' >&2
    exit 2
    ;;
esac
