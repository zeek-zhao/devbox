'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

function reorder(list, from, to) {
  if (from < 0 || from >= list.length || to < 0 || to >= list.length) {
    return list.slice();
  }
  const result = list.slice();
  const [item] = result.splice(from, 1);
  result.splice(to, 0, item);
  return result;
}

async function main() {
  const items = reorder(['write', 'review', 'ship'], 0, 2);
  assert.deepEqual(items, ['review', 'ship', 'write']);
  assert.deepEqual(reorder(items, -1, 0), items);
  const html = await renderToString(
    createSSRApp({
      render: () =>
        h(
          'ol',
          items.map((item) => h('li', { key: item }, item)),
        ),
    }),
  );
  assert.equal(html, '<ol><li>review</li><li>ship</li><li>write</li></ol>');
  console.log(`order=${items.join('>')} ssr=${html}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
