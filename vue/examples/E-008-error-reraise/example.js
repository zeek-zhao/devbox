'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h, onErrorCaptured } = require('vue');
const { renderToString } = require('@vue/server-renderer');

// 重抛决策：中间层 onErrorCaptured 对错误有三种处置——
//   swallow     返回 false，就地吞掉（app 级什么都看不到）；
//   passthrough 返回 undefined，原错误继续上抛；
//   reraise     在钩子里抛出包装错误——Vue 会把新错误以
//               info=errorCaptured hook 送进 app 级，原错误也继续上抛。
const Leaf = {
  setup() {
    return () => {
      throw new Error('leaf boom');
    };
  },
};

async function runMode(mode) {
  const seen = [];
  const Parent = {
    setup() {
      onErrorCaptured((err) => {
        seen.push(`parent-saw:${err.message}`);
        if (mode === 'swallow') {
          return false;
        }
        if (mode === 'reraise') {
          throw new Error(`wrapped: ${err.message}`);
        }
        return undefined;
      });
      return () => h(Leaf);
    },
  };
  const app = createSSRApp(Parent);
  app.config.errorHandler = (err, instance, info) => {
    seen.push(`app-saw:${err.message}|${info}`);
    return false;
  };
  let rejected = null;
  try {
    await renderToString(app);
  } catch (err) {
    rejected = err.message;
  }
  assert.equal(rejected, null);
  return seen;
}

async function main() {
  const swallow = await runMode('swallow');
  assert.deepEqual(swallow, ['parent-saw:leaf boom']);
  const passthrough = await runMode('passthrough');
  assert.deepEqual(passthrough, ['parent-saw:leaf boom', 'app-saw:leaf boom|render function']);
  const reraise = await runMode('reraise');
  assert.equal(reraise[0], 'parent-saw:leaf boom');
  assert.equal(reraise[1], 'app-saw:wrapped: leaf boom|errorCaptured hook');

  console.log(`mode=swallow: parent-saw=true app-reports=0`);
  console.log(`mode=passthrough: parent-saw=true app-reports=1 first=leaf boom`);
  console.log(`mode=reraise: parent-saw=true app-reports=2 first=wrapped: leaf boom`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
