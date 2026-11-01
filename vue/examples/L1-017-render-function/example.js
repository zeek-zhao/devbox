const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const App = {
  render() {
    return h('div', { class: 'a' }, [h('span', 'render'), h('strong', 'function')]);
  },
};

renderToString(createSSRApp(App)).then(console.log);
