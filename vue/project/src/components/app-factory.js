'use strict';

function readTemplate(fs, path, filename) {
  const source = fs.readFileSync(path.join(__dirname, filename), 'utf8');
  const match = /<template>([\s\S]*?)<\/template>/.exec(source);
  if (!match) {
    throw new Error('Missing template in ' + filename);
  }
  return match[1].trim();
}

function createTodoApp(Vue, store, router, templates) {
  const TodoItem = Vue.defineComponent({
    name: 'TodoItem',
    // L1-005-props-one-way: the child receives a required todo and only reads it.
    props: { todo: { type: Object, required: true } },
    // L1-006-emits-declare: row actions are declared component events.
    emits: ['toggle', 'remove'],
    setup: function setup(props, context) {
      // L1-009-provide-inject: each row injects the store provided by its page ancestor.
      const store = Vue.inject('todo-store');
      return { emit: context.emit, remaining: store.remaining };
    },
    render: Vue.compile(templates.todoItem),
  });

  const TodoApp = Vue.defineComponent({
    name: 'TodoApp',
    components: { TodoItem },
    setup: function setup() {
      // L1-001-setup-basics: setup exposes the page's reactive state and handlers to its template.
      Vue.provide('todo-store', store);
      const draftInput = Vue.ref(null);
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

      // L1-010-lifecycle-order: hydration state follows the client mount/unmount lifecycle.
      Vue.onMounted(function markHydrated() {
        store.hydrated.value = true;
      });
      Vue.onUnmounted(function clearHydrated() {
        store.hydrated.value = false;
      });

      return {
        todos: store.todos,
        draft: store.draft,
        remaining: store.remaining,
        route: router.current,
        visibleTodos,
        draftInput,
        addTodo,
        toggleTodo: store.toggleTodo,
        removeTodo: store.removeTodo,
        navigate: router.navigate,
      };
    },
    // L2-002-sfc-template-compile: compile the extracted page SFC template for SSR and hydration.
    render: Vue.compile(templates.todoApp),
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
