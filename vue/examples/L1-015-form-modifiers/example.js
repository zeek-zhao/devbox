const { createSSRApp, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const trimmed = ref('  hello  ');
  const number = ref(0);
  const App = {
    setup() {
      return { trimmed, number };
    },
    template: '<div><input v-model.trim="trimmed"><input v-model.number="number"></div>',
  };

  const html = await renderToString(createSSRApp(App));
  trimmed.value = '  hello  '.trim();
  number.value = Number('42');
  console.log(`trimmed: ${trimmed.value}`);
  console.log(`number: ${number.value}`);
  console.log(`html: ${html}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
