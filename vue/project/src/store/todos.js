'use strict';

function createTodoStore(Vue, initialTodos) {
  // L3-005-composable-reuse: callers reuse this factory while each invocation creates isolated refs.
  // L1-002-ref-vs-reactive and L3-001-proxy-reactivity: Vue proxies the list while ref holds the draft.
  const todos = Vue.reactive(initialTodos.map((todo) => Object.assign({}, todo)));
  // L3-015-custom-ref: the draft explicitly defines dependency tracking for v-model.
  const draft = Vue.customRef((track, trigger) => {
    let value = '';
    return {
      get() {
        track();
        return value;
      },
      set(next) {
        value = next;
        trigger();
      },
    };
  });
  // L1-003-computed-caching: remaining is derived lazily from the reactive todo list.
  const remaining = Vue.computed(() => todos.filter((todo) => !todo.completed).length);
  const hydrated = Vue.ref(false);
  const debugEvents = [];
  const scope = Vue.effectScope();

  scope.run(() => {
    // L1-004-watch-vs-watcheffect and L3-002-effect-scheduler: Vue schedules the title side effect from its reactive read.
    // L1-020-watch-flush: post flush writes the title after Vue's pending view update.
    // L3-016-track-trigger-debug: hooks record which reactive value collects and triggers this effect.
    Vue.watch(
      remaining,
      (count) => {
        if (typeof document !== 'undefined') {
          document.title = count + ' todos remaining';
        }
      },
      {
        immediate: true,
        flush: 'post',
        onTrack: (event) => debugEvents.push(`track:${event.type}:${String(event.key)}`),
        onTrigger: (event) => debugEvents.push(`trigger:${event.type}:${String(event.key)}`),
      },
    );
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

  function moveTodoUp(id) {
    // L3-019-drag-reorder: reorder state without coupling the list operation to browser drag events.
    const index = todos.findIndex((todo) => todo.id === id);
    if (index > 0) {
      const [todo] = todos.splice(index, 1);
      todos.splice(index - 1, 0, todo);
    }
  }

  function replaceTodos(nextTodos) {
    todos.splice(0, todos.length, ...nextTodos.map((todo) => Object.assign({}, todo)));
  }

  function dispose() {
    // L3-013-effect-scope and L3-023-leak-audit: stop all request-scoped effects together.
    scope.stop();
  }

  return {
    todos,
    draft,
    remaining,
    hydrated,
    debugEvents,
    addTodo,
    toggleTodo,
    removeTodo,
    moveTodoUp,
    replaceTodos,
    dispose,
  };
}

if (typeof module === 'object' && module.exports) {
  module.exports = createTodoStore;
} else {
  window.createTodoStore = createTodoStore;
}
