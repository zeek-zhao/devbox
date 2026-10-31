#!/usr/bin/env bash
set -euo pipefail

name='archive.part.tar.gz'
printf 'prefix-short=%s\n' "${name#*.}"
printf 'prefix-long=%s\n' "${name##*.}"
printf 'suffix-short=%s\n' "${name%.*}"
printf 'suffix-long=%s\n' "${name%%.*}"
