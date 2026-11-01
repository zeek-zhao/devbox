'use strict';

const assert = require('node:assert/strict');
const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const App = {
    data: () => ({ tag: 'strong' }),
    template: '<component :is="tag" id="notice">ready</component>',
  };
  const html = await renderToString(createSSRApp(App));
  assert.equal(html, '<strong id="notice">ready</strong>');
  console.log(html);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
