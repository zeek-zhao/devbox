#!/usr/bin/env bash
set -euo pipefail

unset value
printf 'unset-colon=%s\n' "${value:-fallback}"
value=''
printf 'empty-no-colon=<%s>\n' "${value-fallback}"
printf 'empty-colon=%s\n' "${value:-fallback}"
value=ready
printf 'set-colon=%s\n' "${value:-fallback}"
