'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

// 生产报错处理：app.config.errorHandler 是前端错误的统一上报出口。
// 上报的是结构化记录（组件名 + 消息 + 位置类别），不是随手 console.error。
const Card = {
  name: 'Card',
  setup() {
    return () => {
      throw new Error('boom');
    };
  },
};

const Page = {
  name: 'Page',
  async setup() {
    throw new Error('async blew');
  },
  render: () => h('p', 'never'),
};

async function capture(component, reports) {
  const app = createSSRApp({ render: () => h(component) });
  app.config.errorHandler = (err, instance, info) => {
    const componentName =
      instance && instance.$options && instance.$options.name ? instance.$options.name : '-';
    reports.push({ component: componentName, message: err.message, info });
    return false;
  };
  await renderToString(app);
}

async function main() {
  const reports = [];
  await capture(Card, reports);
  await capture(Page, reports);
  assert.equal(reports.length, 2);
  reports.forEach((report) => {
    console.log(
      `report component=${report.component} message=${report.message} info=${report.info}`,
    );
  });
  console.log('reports=2 fields=3 (component, message, info)');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
