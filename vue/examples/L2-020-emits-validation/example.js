'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, defineComponent, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const warnings = [];
  const Child = defineComponent({
    emits: {
      save: (payload) => typeof payload === 'number',
    },
    setup(_props, { emit }) {
      emit('save', 'invalid');
      return () => h('p', 'child');
    },
  });
  const app = createSSRApp(Child);
  app.config.warnHandler = (message) => warnings.push(message);
  const html = await renderToString(app);
  assert.equal(html, '<p>child</p>');
  assert.equal(warnings.length, 1);
  assert.match(warnings[0], /event validation failed for event "save"/);
  console.log('warning=invalid-save-payload html=<p>child</p>');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
