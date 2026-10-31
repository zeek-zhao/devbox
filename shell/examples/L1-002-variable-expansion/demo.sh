#!/usr/bin/env bash
set -euo pipefail

name='two words'
printf 'name=%s\n' "$name"
printf 'braced=%s\n' "${name}"
