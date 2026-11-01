const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  let received;
  const Child = {
    emits: ['add'],
    setup(_props, { emit }) {
      emit('add', 5);
      return {};
    },
    template: '<button>add</button>',
  };
  const App = {
    components: { Child },
    setup() {
      return {
        onAdd(value) {
          received = value;
        },
      };
    },
    template: '<Child @add="onAdd" />',
  };

  const html = await renderToString(createSSRApp(App));
  console.log(`received: ${received}`);
  console.log(html);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
