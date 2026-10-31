#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-001-sfc-compile"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/compile.js" <<'NODE'
const { parse, compileScript } = require('@vue/compiler-sfc');

const source = `
<script setup>
const answer = 42;
</script>
<template><p>{{ answer }}</p></template>
`;
const { descriptor, errors } = parse(source);
if (errors.length > 0) {
  throw errors[0];
}
const compiled = compileScript(descriptor, { id: 'sfc-compile' });
const fragment = compiled.content.match(/const answer = 42;?/);
if (!fragment) {
  throw new Error('compiled setup fragment not found');
}
console.log(fragment[0]);
NODE

node "$TMP_DIR/compile.js"
