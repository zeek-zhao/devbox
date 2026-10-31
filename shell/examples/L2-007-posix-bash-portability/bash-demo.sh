#!/usr/bin/env bash
set -euo pipefail

features=(arrays bash-conditionals)
printf 'bash: features=%s\n' "${#features[@]}"
