#!/usr/bin/env bash
set -euo pipefail

set -- one 'two words'
printf 'at-count=%s\n' "$#"
printf 'at-item=%s\n' "$@"
printf 'star-field=<%s>\n' "$*"
