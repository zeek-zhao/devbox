'use strict';

const assert = require('node:assert/strict');
const { computed, ref } = require('vue');

const source = ref('  write me  ');
const model = computed({
  get: () => source.value.trim(),
  set: (value) => {
    source.value = value;
  },
});

assert.equal(model.value, 'write me');
model.value = 'updated';
assert.equal(source.value, 'updated');
assert.equal(model.value, 'updated');
console.log(`source=${source.value}`);
