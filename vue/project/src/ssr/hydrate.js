'use strict';

function hydrate(Vue, component, store, target) {
  const app = Vue.createSSRApp(component);
  app.provide('todo-store', store);
  // L3-003-hydration-mismatch: mount the caller's app built from the same seed and route as SSR.
  app.mount(target);
  return app;
}

if (typeof module === 'object' && module.exports) {
  module.exports = hydrate;
} else {
  window.hydrate = hydrate;
}
