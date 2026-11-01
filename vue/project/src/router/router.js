'use strict';

function createTodoRouter(Vue, initialPath, onNavigate) {
  const routes = [
    { name: 'todos', pattern: /^\/$/ },
    { name: 'about', pattern: /^\/about$/ },
    { name: 'todo', pattern: /^\/todos\/([^/]+)$/ },
  ];

  function resolve(path) {
    for (const route of routes) {
      const match = route.pattern.exec(path);
      if (match) {
        return {
          name: route.name,
          path,
          params: match[1] ? { id: decodeURIComponent(match[1]) } : {},
        };
      }
    }
    return { name: 'not-found', path, params: {} };
  }

  function beforeEach(to) {
    return to.name === 'not-found' ? resolve('/') : to;
  }

  // L3-014-shallow-markraw: route snapshots are replaced atomically and stay unproxied.
  const current = Vue.shallowReactive({
    value: Vue.markRaw(beforeEach(resolve(initialPath || '/'))),
  });

  function navigate(path) {
    const next = beforeEach(resolve(path));
    current.value = Vue.markRaw(next);
    if (typeof onNavigate === 'function') {
      onNavigate(next.path);
    }
  }

  function restore(path) {
    current.value = Vue.markRaw(beforeEach(resolve(path)));
  }

  return { current, navigate, restore, resolve, beforeEach };
}

if (typeof module === 'object' && module.exports) {
  module.exports = createTodoRouter;
} else {
  window.createTodoRouter = createTodoRouter;
}
