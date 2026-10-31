const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function render(template) {
  const App = {
    data: () => ({ items: ['a', 'b'] }),
    template,
  };
  const app = createSSRApp(App);
  app.config.warnHandler = () => {};
  return renderToString(app);
}

async function main() {
  const keyed = await render('<ul><li v-for="item in items" :key="item">{{ item }}</li></ul>');
  const unkeyed = await render('<ul><li v-for="item in items">{{ item }}</li></ul>');
  console.log(`keyed: ${keyed}`);
  console.log(`unkeyed: ${unkeyed}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
