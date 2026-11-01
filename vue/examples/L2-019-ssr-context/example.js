'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h, Teleport, useSSRContext } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  let modules;
  const Marked = {
    setup() {
      modules = useSSRContext().modules;
      return () => h('span', 'module');
    },
    ssrRender(_ctx, push) {
      modules.add('marked-component');
      push('<span>module</span>');
    },
  };
  const App = {
    render() {
      return h('main', [h(Marked), h(Teleport, { to: '#target' }, [h('b', 'portal')])]);
    },
  };
  const context = { modules: new Set() };
  const html = await renderToString(createSSRApp(App), context);
  assert.ok(html.includes('<span>module</span>'));
  assert.equal(context.modules.has('marked-component'), true);
  assert.ok(context.teleports['#target'].includes('<b>portal</b>'));
  console.log(`html=module teleport=${context.teleports['#target']} modules=marked-component`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
