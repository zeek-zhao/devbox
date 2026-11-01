const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const App = {
  template: '<main><h1>{{ title }}</h1><p>{{ message }}</p></main>',
  data: () => ({ title: 'Vue SSR', message: 'renderToString works' }),
};

renderToString(createSSRApp(App)).then(console.log);
