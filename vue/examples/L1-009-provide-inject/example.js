const { createSSRApp, h, inject, provide } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const Grandchild = {
  setup() {
    const message = inject('message');
    return () => h('p', `injected: ${message}`);
  },
};
const Middle = {
  render: () => h(Grandchild),
};
const Grandparent = {
  setup() {
    provide('message', 'shared value');
    return () => h(Middle);
  },
};

renderToString(createSSRApp(Grandparent)).then(console.log);
