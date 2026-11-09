'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

// 异步错误边界：同步渲染错误与异步 setup 错误都会汇入 app.config.errorHandler
// （info 标明位置），但与组件生命周期无关的游离 Promise 不会——
// 它只能靠显式 catch，漏掉就是 unhandledRejection。
const BROKEN_RENDER = {
  setup() {
    return () => {
      throw new Error('render failed');
    };
  },
};

const BROKEN_ASYNC_SETUP = {
  async setup() {
    throw new Error('async setup failed');
  },
  render: () => h('p', 'never'),
};

async function capture(component, reports) {
  const app = createSSRApp({ render: () => h(component) });
  app.config.errorHandler = (err, instance, info) => {
    reports.push({ message: err.message, info });
    return false;
  };
  await renderToString(app);
}

async function main() {
  const reports = [];

  await capture(BROKEN_RENDER, reports);
  assert.equal(reports.length, 1);
  assert.equal(reports[0].info, 'render function');
  console.log(`sync render error: info=${reports[0].info}`);

  await capture(BROKEN_ASYNC_SETUP, reports);
  assert.equal(reports.length, 2);
  assert.equal(reports[1].info, 'setup function');
  console.log(`async setup error: info=${reports[1].info}`);

  const capturedByCatch = [];
  const detached = Promise.reject(new Error('detached boom'));
  await detached.catch((err) => {
    capturedByCatch.push(err.message);
  });
  assert.equal(reports.length, 2);
  assert.equal(capturedByCatch.length, 1);
  console.log(`detached promise error: app-saw=false caught-by-catch=true`);
  console.log('boundary covered=3 of 3 with explicit catch');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
