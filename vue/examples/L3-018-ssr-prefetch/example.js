'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h, onServerPrefetch, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

function createPage(shouldFail) {
  return {
    setup() {
      const message = ref('loading');
      onServerPrefetch(async () => {
        try {
          if (shouldFail) throw new Error('offline');
          message.value = 'loaded';
        } catch {
          message.value = 'fallback';
        }
      });
      return () => h('p', message.value);
    },
  };
}

async function main() {
  const loaded = await renderToString(createSSRApp(createPage(false)));
  const fallback = await renderToString(createSSRApp(createPage(true)));
  assert.equal(loaded, '<p>loaded</p>');
  assert.equal(fallback, '<p>fallback</p>');
  console.log(`success=${loaded} failure=${fallback}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
