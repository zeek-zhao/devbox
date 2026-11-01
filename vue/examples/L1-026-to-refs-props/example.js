'use strict';

const assert = require('node:assert/strict');
const { reactive, toRefs } = require('vue');

const props = reactive({ label: 'before' });
const direct = props.label;
const { label } = toRefs(props);
props.label = 'after';
assert.equal(direct, 'before');
assert.equal(label.value, 'after');
console.log(`direct=${direct} ref=${label.value}`);
