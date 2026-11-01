'use strict';

function readTemplate(fs, path, filename) {
  const source = fs.readFileSync(path.join(__dirname, filename), 'utf8');
  const match = /<template>([\s\S]*?)<\/template>/.exec(source);
  if (!match) {
    throw new Error('Missing template in ' + filename);
  }
  return match[1].trim();
}

function createTodoApp(
  Vue,
  store,
  router,
  templates,
  loadTodos,
  compilerOptions = { delimiters: ['[[', ']]'] },
) {
  const TodoItem = Vue.defineComponent({
    name: 'TodoItem',
    // L1-005-props-one-way: the child receives a required todo and only reads it.
    props: {
      todo: { type: Object, required: true },
      position: { type: Number, required: true },
    },
    // L1-006-emits-declare: row actions are declared component events.
    // L2-020-emits-validation: the component contract rejects non-string todo identifiers.
    emits: {
      toggle: (id) => typeof id === 'string',
      remove: (id) => typeof id === 'string',
      'move-up': (id) => typeof id === 'string',
    },
    setup: function setup(props, context) {
      // L1-009-provide-inject and L1-025-inject-default: use the provided reactive store or a ref-backed fallback.
      const store = Vue.inject('todo-store', { remaining: Vue.ref(0) });
      // L1-026-to-refs-props: preserve reactivity when exposing the todo prop to the compiled template.
      const { todo } = Vue.toRefs(props);
      return { emit: context.emit, remaining: store.remaining, todo };
    },
    // L2-018-runtime-compiler: Vue.compile is available from the full build in this node-only project.
    render: Vue.compile(templates.todoItem, compilerOptions),
  });

  const TodoApp = Vue.defineComponent({
    name: 'TodoApp',
    components: { TodoItem },
    setup: function setup() {
      // L1-001-setup-basics: setup exposes the page's reactive state and handlers to its template.
      Vue.provide('todo-store', store);
      const draftInput = Vue.ref(null);
      // L1-019-computed-setter: v-model writes through to the store's source ref.
      const draft = Vue.computed({
        get: function getDraft() {
          return store.draft.value;
        },
        set: function setDraft(value) {
          store.draft.value = value;
        },
      });
      const componentError = Vue.ref('');
      // L3-017-error-boundary: child render failures replace the affected page region with a fallback.
      Vue.onErrorCaptured(function captureChildError(error) {
        componentError.value = error.message;
        return false;
      });
      if (typeof loadTodos === 'function') {
        // L3-018-ssr-prefetch: await request data before serializing the server-rendered list.
        Vue.onServerPrefetch(async function prefetchTodos() {
          store.replaceTodos(await loadTodos());
        });
      }
      const visibleTodos = Vue.computed(function visibleTodos() {
        const selectedId = router.current.value.params.id;
        return selectedId ? store.todos.filter((todo) => todo.id === selectedId) : store.todos;
      });

      function addTodo() {
        store.addTodo(store.draft.value);
        // L1-018-nexttick: focus runs after Vue flushes the updated DOM.
        Vue.nextTick(function focusDraft() {
          if (draftInput.value) {
            draftInput.value.focus();
          }
        });
      }

      // L3-019-drag-reorder: the TodoItem action maps to a deterministic list reorder operation.
      function moveTodoUp(id) {
        store.moveTodoUp(id);
      }

      // L1-010-lifecycle-order: hydration state follows the client mount/unmount lifecycle.
      Vue.onMounted(function markHydrated() {
        store.hydrated.value = true;
      });
      Vue.onUnmounted(function clearHydrated() {
        store.hydrated.value = false;
      });

      return {
        todos: store.todos,
        draft,
        remaining: store.remaining,
        route: Vue.computed(function currentRoute() {
          return router.current.value;
        }),
        visibleTodos,
        componentError,
        draftInput,
        addTodo,
        toggleTodo: store.toggleTodo,
        removeTodo: store.removeTodo,
        moveTodoUp,
        navigate: router.navigate,
      };
    },
    // L2-002-sfc-template-compile: compile the extracted page SFC template for SSR and hydration.
    render: Vue.compile(templates.todoApp, compilerOptions),
  });

  return Vue.defineComponent({
    name: 'TodoRoot',
    setup: function setup() {
      return function renderRoot() {
        // L1-017-render-function: h builds the root vnode and its named footer slot.
        return Vue.h(TodoApp, null, {
          // L1-008-slots: the root passes a named footer slot to the page component.
          footer: function footerSlot() {
            return Vue.h('small', 'Server-rendered, then hydrated.');
          },
        });
      };
    },
  });
}

if (typeof module === 'object' && module.exports) {
  module.exports = { createTodoApp, readTemplate };
} else {
  window.createTodoApp = createTodoApp;
}
