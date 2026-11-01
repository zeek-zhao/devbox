const { createSSRApp, onBeforeMount, onBeforeUnmount, onMounted } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const order = [];
  const App = {
    beforeCreate() {
      order.push('beforeCreate');
    },
    setup() {
      order.push('setup');
      onBeforeMount(() => order.push('onBeforeMount'));
      onMounted(() => order.push('onMounted'));
      onBeforeUnmount(() => order.push('onBeforeUnmount'));
      return {};
    },
    created() {
      order.push('created');
    },
    template: '<p>lifecycle</p>',
  };

  const html = await renderToString(createSSRApp(App));
  console.log(order.join(', '));
  console.log(html);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
