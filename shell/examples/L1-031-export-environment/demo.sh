#!/usr/bin/env bash
set -euo pipefail

SETTING='local value'
if bash -c '[ -z "${SETTING+x}" ]'; then
  printf 'unexported variable absent in child: true\n'
else
  printf 'unexported variable absent in child: false\n'
fi

export SETTING
bash -c 'printf "exported child value: %s\n" "$SETTING"'
