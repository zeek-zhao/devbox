const { createSSRApp, onMounted, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const element = ref(null);
  let mountedValue = 'not mounted';
  const App = {
    setup() {
      onMounted(() => {
        mountedValue = element.value;
      });
      return { element };
    },
    template: '<div ref="element">template ref</div>',
  };

  const html = await renderToString(createSSRApp(App));
  console.log(html);
  console.log(`template ref: ${element.value === null ? 'null' : 'set'}`);
  console.log(`onMounted: ${mountedValue}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
