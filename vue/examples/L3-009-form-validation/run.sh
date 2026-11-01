#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-009-form-validation"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const rules = [
  { type: 'required', message: 'required' },
  { type: 'min', limit: 3, message: 'min:3' },
  { type: 'max', limit: 5, message: 'max:5' },
];
const validators = {
  required: (value) => value.trim().length > 0,
  min: (value, rule) => value.length >= rule.limit,
  max: (value, rule) => value.length <= rule.limit,
};
function validate(value) {
  for (const rule of rules) {
    if (!Object.hasOwn(validators, rule.type)) throw new Error(`Unknown rule: ${rule.type}`);
    if (!validators[rule.type](value, rule)) return rule.message;
  }
  return 'valid';
}
const View = {
  props: { value: { type: String, required: true } },
  setup(props) {
    return () => h('p', { 'data-input': props.value }, validate(props.value));
  },
};

async function main() {
  console.log(`rules=${rules.map((rule) => rule.type).join('->')}`);
  for (const value of ['', 'ab', 'abcdef', 'vue']) {
    console.log(await renderToString(createSSRApp(View, { value })));
  }
  assert.equal(validate('   '), 'required');
  assert.equal(validate('abcde'), 'valid');
  assert.equal(validate('abc'), 'valid');
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
