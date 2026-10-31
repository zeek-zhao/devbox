#!/usr/bin/env bash
set -euo pipefail

if false; then
  status=0
else
  status=$?
fi
printf 'false_status=%s\n' "$status"

if true; then
  printf 'true_branch=success\n'
else
  printf 'true_branch=failure\n'
fi
