const { createSSRApp, getCurrentInstance } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function render(template) {
  let receivedProps;
  const Child = {
    props: ['modelValue'],
    emits: ['update:modelValue'],
    setup(props) {
      receivedProps = Object.keys(getCurrentInstance().vnode.props).sort();
      return { modelValue: props.modelValue };
    },
    template: '<p>{{ modelValue }}</p>',
  };
  const App = {
    components: { Child },
    data: () => ({ value: 7 }),
    template,
  };

  const html = await renderToString(createSSRApp(App));
  return { html, receivedProps };
}

async function main() {
  const model = await render('<Child v-model="value" />');
  const manual = await render('<Child :modelValue="value" @update:modelValue="value = $event" />');
  console.log(`v-model props: ${model.receivedProps.join(', ')}`);
  console.log(`manual props: ${manual.receivedProps.join(', ')}`);
  console.log(`v-model html: ${model.html}`);
  console.log(`manual html: ${manual.html}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
