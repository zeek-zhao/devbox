'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h, inject, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const shared = ref('first');
  const Child = {
    setup() {
      return { value: inject('message', ref('fallback')) };
    },
    render() {
      return h('p', this.value);
    },
  };
  const App = {
    setup() {
      return () => h(Child);
    },
  };
  const app = createSSRApp(App);
  app.provide('message', shared);
  assert.equal(await renderToString(app), '<p>first</p>');
  shared.value = 'second';
  const updatedApp = createSSRApp(App);
  updatedApp.provide('message', shared);
  assert.equal(await renderToString(updatedApp), '<p>second</p>');
  const fallbackApp = createSSRApp(Child);
  assert.equal(await renderToString(fallbackApp), '<p>fallback</p>');
  console.log('provided=second fallback=fallback');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
