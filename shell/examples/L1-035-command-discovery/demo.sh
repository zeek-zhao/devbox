#!/usr/bin/env bash
set -euo pipefail

work=$1
if command -v bash >/dev/null; then
  printf 'bash executable found: true\n'
else
  printf 'bash executable found: false\n'
fi

mkdir "$work/empty-path"
if env -i PATH="$work/empty-path" bash -c 'command -v devbox-required-tool' >/dev/null; then
  printf 'missing dependency rejected: false\n'
else
  printf 'missing dependency rejected: true\n'
fi
