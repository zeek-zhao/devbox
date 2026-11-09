'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

// 错误分类与类型体系：Vue 的错误来自不同源头（setup 抛错 / render 抛错 /
// 异步 setup 的 Promise 拒绝），但都汇入 app.config.errorHandler，
// info 字段标明出错位置类别。分类（而不是消息文本）决定处理策略。
const BROKEN_SETUP = {
  setup() {
    throw new Error('setup failed');
  },
};

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
};

async function captureSource(component) {
  const reports = [];
  const app = createSSRApp({ render: () => h(component) });
  app.config.errorHandler = (err, instance, info) => {
    reports.push({ message: err.message, info });
    return false;
  };
  await renderToString(app);
  assert.equal(reports.length, 1);
  return reports[0];
}

async function main() {
  const setupReport = await captureSource(BROKEN_SETUP);
  const renderReport = await captureSource(BROKEN_RENDER);
  const asyncReport = await captureSource(BROKEN_ASYNC_SETUP);
  console.log(`source=setup error=${setupReport.message} info=${setupReport.info}`);
  console.log(`source=render error=${renderReport.message} info=${renderReport.info}`);
  console.log(`source=async error=${asyncReport.message} info=${asyncReport.info}`);
  console.log('taxonomy sync=2 async=1 captured=3');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
