'use strict';

const { renderToString } = require('@vue/server-renderer');

function createSSRApp(Vue, component, store) {
  // L1-016-ssr-basic: each server request creates an SSR app before renderToString.
  const app = Vue.createSSRApp(component);
  app.provide('todo-store', store);
  return app;
}

function renderSSR(app) {
  // hello: renderToString produces the deterministic HTML consumed by the smoke check.
  return renderToString(app);
}

module.exports = { createSSRApp, renderSSR };
