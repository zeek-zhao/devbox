const { createSSRApp, nextTick, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const count = ref(0);
  const App = {
    setup() {
      return { count };
    },
    template: '<p>{{ count }}</p>',
  };
  const domProxy = null;

  count.value = 1;
  console.log(`DOM proxy immediately: ${domProxy === null ? 'unavailable' : 'available'}`);
  await nextTick();
  console.log(`DOM proxy after nextTick: ${domProxy === null ? 'unavailable' : 'available'}`);
  console.log(`SSR html: ${await renderToString(createSSRApp(App))}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
