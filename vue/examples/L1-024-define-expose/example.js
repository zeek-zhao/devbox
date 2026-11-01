'use strict';

const assert = require('node:assert/strict');
const { compileScript, parse } = require('@vue/compiler-sfc');

const source = `
<script setup>
const count = 1;
const secret = 'private';
defineExpose({ count });
</script>
<template><p>{{ count }}</p></template>
`;
const { descriptor, errors } = parse(source);
assert.deepEqual(errors, []);
const compiled = compileScript(descriptor, { id: 'expose-demo' }).content;
assert.match(compiled, /__expose\(\{\s*count\s*\}\)/);
assert.doesNotMatch(compiled, /__expose\(\{[^}]*secret/);
console.log('exposed=count; private=secret');
