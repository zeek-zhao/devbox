#!/usr/bin/env bash
set -euo pipefail

args=(-n 'two words; printf unexpected')
printer=(printf 'argument: <%s>\n')
printf 'argument count: %s\n' "${#args[@]}"
"${printer[@]}" "${args[@]}"
