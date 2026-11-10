'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h, onErrorCaptured } = require('vue');
const { renderToString } = require('@vue/server-renderer');

// 错误上下文：多层组件嵌套时，每一层的 onErrorCaptured 把自己的名字
// 追加进错误对象的 context 字段再放行（return undefined，不拦截）——
// app 级 errorHandler 收到的错误自带完整层级路径。
class AppError extends Error {
  constructor(message, context) {
    super(message);
    this.name = 'AppError';
    this.context = context;
  }
}

const Leaf = {
  setup() {
    return () => {
      throw new AppError('leaf boom', 'Leaf');
    };
  },
};

const Mid = {
  setup() {
    onErrorCaptured((err) => {
      err.context = `Mid > ${err.context}`;
      return undefined;
    });
    return () => h(Leaf);
  },
};

const Root = {
  setup() {
    onErrorCaptured((err) => {
      err.context = `Root > ${err.context}`;
      return undefined;
    });
    return () => h(Mid);
  },
};

async function main() {
  const reports = [];
  const app = createSSRApp(Root);
  app.config.errorHandler = (err) => {
    reports.push({ message: err.message, context: err.context });
    return false;
  };
  await renderToString(app);
  assert.equal(reports.length, 1);
  assert.equal(reports[0].message, 'leaf boom');
  assert.equal(reports[0].context, 'Root > Mid > Leaf');
  console.log(`message=${reports[0].message}`);
  console.log(`context path=${reports[0].context}`);
  console.log('path depth=3');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
