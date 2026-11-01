'use strict';

const assert = require('node:assert/strict');
const { effectScope, nextTick, ref, watchEffect } = require('vue');

async function main() {
  const value = ref(0);
  const seen = [];
  const scope = effectScope();
  scope.run(() => watchEffect(() => seen.push(value.value)));
  value.value = 1;
  await nextTick();
  scope.stop();
  value.value = 2;
  await nextTick();
  assert.deepEqual(seen, [0, 1]);
  console.log(`effects=${seen.join(',')} stopped=true`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
