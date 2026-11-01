const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const App = {
  data: () => ({ visible: false }),
  template: '<div><p v-if="visible">if</p><p v-show="visible">show</p></div>',
};

renderToString(createSSRApp(App)).then(console.log);
