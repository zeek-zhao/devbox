'use strict';

const assert = require('node:assert/strict');
const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const app = createSSRApp({ template: '<p>[[ $appName ]]</p>' });
  app.config.globalProperties.$appName = 'Devbox';
  app.config.compilerOptions.delimiters = ['[[', ']]'];
  const html = await renderToString(app);
  assert.equal(html, '<p>Devbox</p>');
  const failures = [];
  const failingApp = createSSRApp({
    setup() {
      throw new Error('captured');
    },
    template: '<p>fallback</p>',
  });
  failingApp.config.errorHandler = (error) => {
    failures.push(error.message);
  };
  const fallbackHtml = await renderToString(failingApp);
  assert.equal(fallbackHtml, '<p>fallback</p>');
  assert.deepEqual(failures, ['captured']);
  console.log('html=<p>Devbox</p> errorHandler=captured');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
