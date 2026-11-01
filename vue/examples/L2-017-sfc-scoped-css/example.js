'use strict';

const assert = require('node:assert/strict');
const { compileStyle } = require('@vue/compiler-sfc');

const result = compileStyle({
  filename: 'Widget.vue',
  id: 'data-v-widget',
  scoped: true,
  source: '.box { color: red } .box :deep(.child) { margin: 0 }',
});
assert.deepEqual(result.errors, []);
assert.match(result.code, /\.box\[data-v-widget\]/);
assert.match(result.code, /\.box\[data-v-widget\] \.child/);
console.log('scoped=.box[data-v-widget] deep=.box[data-v-widget] .child');
