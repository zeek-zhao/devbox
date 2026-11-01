'use strict';

const fs = require('fs');
const path = require('path');
const serverRendererPath = require.resolve('@vue/server-renderer');
const runtimePath = require.resolve('@vue/runtime-dom', {
  paths: [path.dirname(serverRendererPath)],
});
const VueRuntime = require(runtimePath);
const compiler = require(
  require.resolve('@vue/compiler-dom', {
    paths: [path.dirname(require.resolve('vue'))],
  }),
);
// The global SSR renderer and Vue package contain separate runtime-core copies; compile against the renderer's runtime.
const Vue = Object.assign({}, VueRuntime, {
  compile(template, options) {
    const result = compiler.compile(template, Object.assign({ mode: 'function' }, options));
    if (result.errors && result.errors.length > 0) {
      throw result.errors[0];
    }
    return new Function('Vue', result.code)(VueRuntime);
  },
});
// L2-003-multifile-modules: the server composes independently maintained store, router, and component modules.
const createTodoStore = require('./store/todos');
const createTodoRouter = require('./router/router');
const { createTodoApp, readTemplate } = require('./components/app-factory');
const { createSSRApp } = require('./ssr/render');

const initialTodos = [
  { id: 'todo-1', text: 'Learn Vue SSR', completed: false },
  { id: 'todo-2', text: 'Hydrate the todo list', completed: true },
];

function createApplication(urlPath) {
  const store = createTodoStore(Vue, []);
  const router = createTodoRouter(Vue, urlPath, function updateHistory(pathname) {
    if (typeof history !== 'undefined') {
      history.pushState({}, '', pathname);
    }
  });
  const templates = {
    todoApp: readTemplate(fs, path, 'TodoApp.vue'),
    todoItem: readTemplate(fs, path, 'TodoItem.vue'),
  };
  const compilerOptions = { delimiters: ['[[', ']]'] };
  const component = createTodoApp(
    Vue,
    store,
    router,
    templates,
    async function loadTodos() {
      return initialTodos;
    },
    compilerOptions,
  );
  const app = createSSRApp(Vue, component, store);
  app.config.errorHandler = function handleAppError(error) {
    console.error('Vue application error:', error);
  };
  // L2-021-app-config: app globals and errors use app config; delimiters go to compiler-dom for this runtime-only SSR host.
  app.config.globalProperties.$projectName = 'Devbox todos';
  return { app, store, router };
}

module.exports = { createApplication, initialTodos };
