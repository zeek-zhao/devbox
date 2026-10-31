const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const App = {
  render() {
    return h('div', [
      h('p', { class: { active: true, muted: false }, style: { color: 'red' } }, 'object'),
      h('p', { class: ['base', false, { active: true }] }, 'array'),
      h('p', { class: 'plain' }, 'string'),
    ]);
  },
};

renderToString(createSSRApp(App)).then((html) => {
  for (const match of html.matchAll(/<p[^>]*>[^<]*<\/p>/g)) {
    console.log(match[0]);
  }
});
