'use strict';

const assert = require('node:assert/strict');
const { effectScope, nextTick, ref, watchEffect } = require('vue');

async function main() {
  const value = ref(0);
  let scopedRuns = 0;
  let manualRuns = 0;
  const scope = effectScope();
  scope.run(() =>
    watchEffect(() => {
      value.value;
      scopedRuns += 1;
    }),
  );
  const stopManual = watchEffect(() => {
    value.value;
    manualRuns += 1;
  });
  value.value = 1;
  await nextTick();
  scope.stop();
  stopManual();
  value.value = 2;
  await nextTick();
  assert.deepEqual([scopedRuns, manualRuns], [2, 2]);
  console.log(`scoped=${scopedRuns} manual=${manualRuns} after-stop=unchanged`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
