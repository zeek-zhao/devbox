#!/usr/bin/env bash
set -euo pipefail

if true; then
  printf 'success command: then branch\n'
else
  printf 'success command: else branch\n'
fi

if false; then
  printf 'nonzero command: then branch\n'
else
  printf 'nonzero command: else branch\n'
fi
