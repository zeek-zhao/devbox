'use strict';

const assert = require('node:assert/strict');
const { withModifiers } = require('vue');

let calls = 0;
let prevented = 0;
let stopped = 0;
const handler = withModifiers(() => {
  calls += 1;
}, ['prevent', 'stop']);
const event = {
  preventDefault() {
    prevented += 1;
  },
  stopPropagation() {
    stopped += 1;
  },
};

handler(event);
assert.deepEqual([calls, prevented, stopped], [1, 1, 1]);
let onceCalls = 0;
let once = true;
const onceHandler = (eventValue) => {
  if (once) {
    once = false;
    handler(eventValue);
    onceCalls += 1;
  }
};
onceHandler(event);
onceHandler(event);
assert.deepEqual([calls, onceCalls, prevented, stopped], [2, 1, 2, 2]);
console.log(`calls=${calls} once=${onceCalls} prevented=${prevented} stopped=${stopped}`);
