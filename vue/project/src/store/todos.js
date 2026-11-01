'use strict';

function createTodoStore(Vue, initialTodos) {
  // L3-005-composable-reuse: callers reuse this factory while each invocation creates isolated refs.
  // L1-002-ref-vs-reactive and L3-001-proxy-reactivity: Vue proxies the list while ref holds the draft.
  const todos = Vue.reactive(initialTodos.map((todo) => Object.assign({}, todo)));
  const draft = Vue.ref('');
  // L1-003-computed-caching: remaining is derived lazily from the reactive todo list.
  const remaining = Vue.computed(() => todos.filter((todo) => !todo.completed).length);
  const hydrated = Vue.ref(false);

  Vue.watchEffect(() => {
    // L1-004-watch-vs-watcheffect and L3-002-effect-scheduler: Vue schedules the title side effect from its reactive read.
    if (typeof document !== 'undefined') {
      document.title = remaining.value + ' todos remaining';
    }
  });

  function addTodo(text) {
    const value = text.trim();
    if (!value) {
      return;
    }
    todos.push({
      id: 'todo-' + (todos.length + 1),
      text: value,
      completed: false,
    });
    draft.value = '';
  }

  function toggleTodo(id) {
    const todo = todos.find((item) => item.id === id);
    if (todo) {
      todo.completed = !todo.completed;
    }
  }

  function removeTodo(id) {
    const index = todos.findIndex((todo) => todo.id === id);
    if (index !== -1) {
      todos.splice(index, 1);
    }
  }

  return {
    todos,
    draft,
    remaining,
    hydrated,
    addTodo,
    toggleTodo,
    removeTodo,
  };
}

if (typeof module === 'object' && module.exports) {
  module.exports = createTodoStore;
} else {
  window.createTodoStore = createTodoStore;
}
