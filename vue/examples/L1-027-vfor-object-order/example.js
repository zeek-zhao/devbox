'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const values = { zebra: 'z', 2: 'two', alpha: 'a', 1: 'one' };
  const map = new Map([
    ['zebra', 'z'],
    ['alpha', 'a'],
  ]);
  const App = {
    render() {
      return h('ul', [
        ...Object.keys(values).map((key) => h('li', { key, 'data-key': key }, values[key])),
        ...Array.from(map, ([key, value]) => h('li', { key, 'data-key': key }, value)),
      ]);
    },
  };
  const html = await renderToString(createSSRApp(App));
  assert.match(html, /data-key="1".*data-key="2".*data-key="zebra".*data-key="alpha"/);
  assert.doesNotMatch(html, /\skey=/);
  console.log('object=1,2,zebra,alpha map=zebra,alpha key-attribute=absent');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
