'use strict';

const assert = require('node:assert/strict');
const {
  isReactive,
  markRaw,
  nextTick,
  reactive,
  shallowReactive,
  shallowRef,
  watchEffect,
} = require('vue');

async function main() {
  const state = shallowRef({ count: 0 });
  const shallow = shallowReactive({ nested: { count: 0 } });
  const raw = markRaw({ value: 1 });
  const container = reactive({ raw });
  let runs = 0;
  watchEffect(() => {
    state.value.count;
    shallow.nested.count;
    runs += 1;
  });

  state.value.count += 1;
  shallow.nested.count += 1;
  assert.equal(runs, 1);
  state.value = { count: 2 };
  await nextTick();
  assert.equal(runs, 2);
  assert.equal(isReactive(shallow.nested), false);
  assert.equal(isReactive(container.raw), false);
  console.log(
    `runs=${runs} nested-reactive=${isReactive(shallow.nested)} raw-reactive=${isReactive(container.raw)}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
