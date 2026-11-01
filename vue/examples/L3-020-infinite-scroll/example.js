'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

function loadWindow(items, loaded, batchSize) {
  return items.slice(0, Math.min(loaded + batchSize, items.length));
}

async function main() {
  const items = ['a', 'b', 'c', 'd', 'e'];
  const first = loadWindow(items, 0, 2);
  const second = loadWindow(items, first.length, 2);
  assert.deepEqual(first, ['a', 'b']);
  assert.deepEqual(second, ['a', 'b', 'c', 'd']);
  const html = await renderToString(
    createSSRApp({
      render: () =>
        h(
          'ul',
          second.map((item) => h('li', { key: item }, item)),
        ),
    }),
  );
  assert.equal((html.match(/<li>/g) || []).length, 4);
  console.log(`loaded=${first.length}->${second.length} total=${items.length}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
