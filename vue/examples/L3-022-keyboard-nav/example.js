'use strict';

const assert = require('node:assert/strict');

function nextIndex(key, current, length) {
  if (length === 0) return -1;
  if (key === 'Home') return 0;
  if (key === 'End') return length - 1;
  if (key === 'ArrowRight') return (current + 1) % length;
  if (key === 'ArrowLeft') return (current - 1 + length) % length;
  return current;
}

const sequence = [
  nextIndex('ArrowRight', 0, 3),
  nextIndex('ArrowRight', 2, 3),
  nextIndex('Home', 2, 3),
  nextIndex('End', 0, 3),
  nextIndex('ArrowRight', 0, 0),
];
assert.deepEqual(sequence, [1, 0, 0, 2, -1]);
console.log(`indices=${sequence.join(',')}`);
