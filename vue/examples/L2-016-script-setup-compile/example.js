'use strict';

const assert = require('node:assert/strict');
const { compileScript, parse } = require('@vue/compiler-sfc');

const { descriptor, errors } = parse(`
<script setup>
defineProps({ label: String });
const suffix = '!';
</script>
<template><p>{{ label }}{{ suffix }}</p></template>
`);
assert.deepEqual(errors, []);
const result = compileScript(descriptor, { id: 'inline-demo', inlineTemplate: true }).content;
assert.match(result, /props:\s*\{\s*label:\s*String\s*\}/);
assert.match(result, /return \(_ctx, _cache\)/);
assert.match(result, /suffix/);
console.log('props=hoisted template=inline');
