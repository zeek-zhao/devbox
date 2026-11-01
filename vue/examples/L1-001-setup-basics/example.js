const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const App = {
  setup() {
    return { msg: 'hello from setup' };
  },
  template: '<p>{{ msg }}</p>',
};

renderToString(createSSRApp(App)).then(console.log);
