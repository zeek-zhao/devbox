'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const Vue = require('vue');

const fullRender = Vue.compile('<p>{{ message }}</p>');
const dist = path.join(path.dirname(require.resolve('vue')), 'dist');
const runtimeContext = {};
vm.runInNewContext(
  fs.readFileSync(path.join(dist, 'vue.runtime.global.js'), 'utf8'),
  runtimeContext,
);
const runtimeRender = runtimeContext.Vue.compile('<p>{{ message }}</p>');

assert.equal(typeof fullRender, 'function');
assert.equal(runtimeRender, undefined);
console.log(`full-template=${typeof fullRender} runtime-template=${String(runtimeRender)}`);
