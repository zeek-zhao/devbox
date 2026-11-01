'use strict';

(async function hydrateTodoApp() {
  const Vue = window.Vue;
  const [todoSource, itemSource] = await Promise.all([
    fetch('/src/components/TodoApp.vue').then((response) => response.text()),
    fetch('/src/components/TodoItem.vue').then((response) => response.text()),
  ]);
  const templateFrom = function templateFrom(source) {
    const match = /<template>([\s\S]*?)<\/template>/.exec(source);
    if (!match) {
      throw new Error('SFC template is missing');
    }
    return match[1].trim();
  };
  const store = window.createTodoStore(Vue, [
    { id: 'todo-1', text: 'Learn Vue SSR', completed: false },
    { id: 'todo-2', text: 'Hydrate the todo list', completed: true },
  ]);
  const router = window.createTodoRouter(
    Vue,
    window.__INITIAL_PATH__ || window.location.pathname,
    function updateHistory(pathname) {
      window.history.pushState({}, '', pathname);
    },
  );
  window.addEventListener('popstate', function restoreRoute() {
    router.restore(window.location.pathname);
  });
  const component = window.createTodoApp(Vue, store, router, {
    todoApp: templateFrom(todoSource),
    todoItem: templateFrom(itemSource),
  });
  window.hydrate(Vue, component, store, '#app');
  window.addEventListener('pagehide', store.dispose, { once: true });
  window.__TODO_STORE__ = store;
  window.__TODO_HYDRATED__ = true;
})().catch(function hydrationFailed(error) {
  console.error('Vue hydration failed:', error);
});
