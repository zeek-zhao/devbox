'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h, onErrorCaptured, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  let captured = '';
  const Broken = {
    setup() {
      return () => {
        throw new Error('child failed');
      };
    },
  };
  const Boundary = {
    setup() {
      const failed = ref(false);
      onErrorCaptured((error) => {
        captured = error.message;
        failed.value = true;
        return false;
      });
      return () => h('main', [failed.value ? h('p', { role: 'alert' }, 'fallback') : h(Broken)]);
    },
  };
  await renderToString(createSSRApp(Boundary));
  assert.equal(captured, 'child failed');
  const Fallback = {
    setup() {
      return () => h('main', [captured ? h('p', { role: 'alert' }, 'fallback') : h(Broken)]);
    },
  };
  const html = await renderToString(createSSRApp(Fallback));
  assert.ok(html.includes('fallback'));
  console.log(`captured=${captured} fallback=${html.includes('fallback')}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
