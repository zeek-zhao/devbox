'use strict';

const assert = require('node:assert/strict');
const { nextTick, ref, watch } = require('vue');

async function main() {
  const value = ref(0);
  const calls = [];
  watch(value, () => calls.push('pre'), { flush: 'pre' });
  watch(value, () => calls.push('post'), { flush: 'post' });
  watch(value, () => calls.push('sync'), { flush: 'sync' });

  value.value = 1;
  assert.deepEqual(calls, ['sync']);
  await nextTick();
  assert.deepEqual(calls, ['sync', 'pre', 'post']);
  console.log(calls.join(' -> '));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
