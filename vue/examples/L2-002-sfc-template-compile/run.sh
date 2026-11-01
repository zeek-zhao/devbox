#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-002-sfc-template-compile"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/compile.js" <<'NODE'
const { compileTemplate, parse } = require('@vue/compiler-sfc');

const source = '<template><p>{{ message }}</p></template>';
const { descriptor, errors } = parse(source);
if (errors.length > 0) {
  throw errors[0];
}
const options = {
  filename: 'Deterministic.vue',
  id: 'deterministic',
  source: descriptor.template.content,
};
const first = compileTemplate(options);
const second = compileTemplate(options);
if (first.errors.length > 0 || second.errors.length > 0) {
  throw first.errors[0] || second.errors[0];
}
console.log(first.code === second.code ? 'deterministic' : 'different');
NODE

node "$TMP_DIR/compile.js"
