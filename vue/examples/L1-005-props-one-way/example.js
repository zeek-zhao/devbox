const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const Child = {
  props: ['message'],
  template: '<p>{{ message }}</p>',
};
const App = {
  components: { Child },
  setup() {
    return { message: 'from parent' };
  },
  template: '<Child :message="message" />',
};

renderToString(createSSRApp(App)).then(console.log);
