#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-004-unit-test-harness"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/test.js" <<'NODE'
let passed = 0;

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    throw new Error(`${label}: expected ${expected}, received ${actual}`);
  }
  passed += 1;
}

assertEqual(1 + 1, 2, 'addition');
assertEqual('vue'.toUpperCase(), 'VUE', 'uppercase');
assertEqual([1, 2].length, 2, 'array length');
assertEqual(Boolean('ready'), true, 'truthy value');
console.log(`${passed} passed`);
NODE

node "$TMP_DIR/test.js"
