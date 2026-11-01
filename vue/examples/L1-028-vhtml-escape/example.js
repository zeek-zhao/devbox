'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const untrusted = '<img src=x onerror=alert(1)>';
  const App = {
    render() {
      return h('div', [h('p', untrusted), h('section', { innerHTML: untrusted })]);
    },
  };
  const html = await renderToString(createSSRApp(App));
  assert.ok(html.includes('&lt;img src=x onerror=alert(1)&gt;'));
  assert.ok(html.includes('<section><img src=x onerror=alert(1)></section>'));
  console.log('text=escaped html=raw');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
