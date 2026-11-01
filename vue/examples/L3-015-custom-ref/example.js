'use strict';

const assert = require('node:assert/strict');
const { customRef, watchEffect } = require('vue');

function useDebouncedRef(initialValue, delay) {
  let value = initialValue;
  let timer;
  return customRef((track, trigger) => ({
    get() {
      track();
      return value;
    },
    set(next) {
      clearTimeout(timer);
      timer = setTimeout(() => {
        value = next;
        trigger();
      }, delay);
    },
  }));
}

async function main() {
  const query = useDebouncedRef('', 5);
  const seen = [];
  watchEffect(() => seen.push(query.value));
  query.value = 'v';
  query.value = 'vue';
  assert.deepEqual(seen, ['']);
  await new Promise((resolve) => setTimeout(resolve, 15));
  assert.deepEqual(seen, ['', 'vue']);
  console.log(`values=${seen.join(',')}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
