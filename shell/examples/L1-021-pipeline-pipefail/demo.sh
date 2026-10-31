#!/usr/bin/env bash
set -euo pipefail

set +o pipefail
if false | true; then
  printf 'default_pipeline=success\n'
else
  printf 'default_pipeline=failure\n'
fi

set -o pipefail
if false | true; then
  printf 'pipefail_pipeline=success\n'
else
  printf 'pipefail_pipeline=failure\n'
fi
