'use strict';

const fs = require('fs');
const path = require('path');
const Vue = require('vue');
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
  const store = createTodoStore(Vue, initialTodos);
  const router = createTodoRouter(Vue, urlPath, function updateHistory(pathname) {
    if (typeof history !== 'undefined') {
      history.pushState({}, '', pathname);
    }
  });
  const templates = {
    todoApp: readTemplate(fs, path, 'TodoApp.vue'),
    todoItem: readTemplate(fs, path, 'TodoItem.vue'),
  };
  const component = createTodoApp(Vue, store, router, templates);
  const app = createSSRApp(Vue, component, store);
  app.config.errorHandler = function handleAppError(error) {
    console.error('Vue application error:', error);
  };
  return { app, store, router };
}

module.exports = { createApplication, initialTodos };
