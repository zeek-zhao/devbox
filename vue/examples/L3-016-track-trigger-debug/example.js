'use strict';

const assert = require('node:assert/strict');
const { nextTick, ref, watchEffect } = require('vue');

async function main() {
  const count = ref(0);
  const events = [];
  watchEffect(
    () => {
      count.value;
    },
    {
      onTrack: (event) => events.push(`track:${event.type}:${String(event.key)}`),
      onTrigger: (event) => events.push(`trigger:${event.type}:${String(event.key)}`),
    },
  );
  count.value += 1;
  await nextTick();
  assert.deepEqual(events, ['track:get:value', 'trigger:set:value', 'track:get:value']);
  console.log(events.join(' -> '));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
