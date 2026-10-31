const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const Panel = {
  setup(_props, { slots }) {
    return () =>
      h('section', [
        h('header', slots.header()),
        h('main', slots.default()),
        h('footer', slots.item({ name: 'Ada' })),
      ]);
  },
};
const App = {
  render() {
    return h(
      Panel,
      {},
      {
        default: () => h('p', 'body'),
        header: () => h('h1', 'title'),
        item: ({ name }) => h('span', name),
      },
    );
  },
};

renderToString(createSSRApp(App)).then(console.log);
