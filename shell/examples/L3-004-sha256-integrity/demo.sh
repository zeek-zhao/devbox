#!/usr/bin/env bash
set -euo pipefail

expected='4a209530d5767e6dfe9aceebaf244fb23d805666f67c8fbba1c279669a2bea5d'
printf 'artifact=devbox\n' > "$WORK/artifact.txt"
actual="$(sha256sum "$WORK/artifact.txt" | awk '{print $1}')"
if [[ "$actual" != "$expected" ]]; then
  printf 'original: mismatch\n' >&2
  exit 1
fi
printf 'original: verified\n'

printf 'X' >> "$WORK/artifact.txt"
changed="$(sha256sum "$WORK/artifact.txt" | awk '{print $1}')"
if [[ "$changed" == "$expected" ]]; then
  printf 'modified: change not detected\n' >&2
  exit 1
fi
printf 'modified: change detected\n'
