#!/usr/bin/env bash
set -euo pipefail

true && false || printf 'command list fallback ran\n'

if true; then
  if false; then
    printf 'if branch: second step succeeded\n'
  else
    printf 'if branch: second step failed\n'
  fi
else
  printf 'if branch: first step failed\n'
fi
