'use strict';

const Vue = require('vue');
const { renderToString } = require('@vue/server-renderer');
const { performance } = require('perf_hooks');

async function main() {
  const todos = Array.from({ length: 1000 }, function makeTodo(_, index) {
    return { id: 'todo-' + (index + 1), text: 'Todo ' + (index + 1) };
  });
  // L3-012-render-perf-baseline: render a fixed 1000-item input and observe the actual SSR result.
  const List = Vue.defineComponent({
    props: { items: { type: Array, required: true } },
    template:
      '<ul><li v-for="item in items" :key="item.id" class="todo-item">{{ item.text }}</li></ul>',
  });
  const start = performance.now();
  const html = await renderToString(Vue.createSSRApp(List, { items: todos }));
  const elapsed = performance.now() - start;
  const itemCount = (html.match(/class="todo-item"/g) || []).length;
  if (itemCount !== 1000) {
    throw new Error('Expected 1000 rendered todos, found ' + itemCount);
  }
  console.error(
    'SSR baseline: rendered ' +
      itemCount +
      ' todos in ' +
      elapsed.toFixed(2) +
      ' ms (observation only)',
  );
}

main().catch(function reportFailure(error) {
  console.error(error);
  process.exitCode = 1;
});
