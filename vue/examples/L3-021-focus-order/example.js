'use strict';

const assert = require('node:assert/strict');

function focusOrder(items) {
  return items
    .filter((item) => !item.disabled)
    .map((item, index) => ({ id: item.id, tabindex: index === 0 ? 0 : -1 }));
}

const order = focusOrder([{ id: 'first' }, { id: 'hidden', disabled: true }, { id: 'last' }]);
assert.deepEqual(order, [
  { id: 'first', tabindex: 0 },
  { id: 'last', tabindex: -1 },
]);
console.log(`focus=${order.map((item) => `${item.id}:${item.tabindex}`).join(',')}`);
