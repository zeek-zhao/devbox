#!/usr/bin/env bash
set -euo pipefail

cleanup() {
  rm -f "$WORK/active"
  printf 'worker: TERM handled\n'
  exit 143
}

trap cleanup TERM
touch "$WORK/active"
printf 'worker: ready\n'
touch "$WORK/ready"

while :; do
  :
done
