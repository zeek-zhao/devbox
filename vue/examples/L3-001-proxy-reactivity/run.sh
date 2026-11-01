#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-001-proxy-reactivity"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const proxies = new WeakMap();
const originals = new WeakMap();
let created = 0;

function reactive(target) {
  if (target === null || typeof target !== 'object') return target;
  if (originals.has(target)) return target;
  if (proxies.has(target)) return proxies.get(target);
  const proxy = new Proxy(target, {
    get(object, key, receiver) {
      return reactive(Reflect.get(object, key, receiver));
    },
    set(object, key, value, receiver) {
      return Reflect.set(object, key, originals.get(value) || value, receiver);
    },
  });
  proxies.set(target, proxy);
  originals.set(proxy, target);
  created++;
  return proxy;
}

const raw = {
  count: 1,
  nested: { value: 10 },
  get doubled() {
    return this.count * 2;
  },
  set doubled(value) {
    this.count = value / 2;
  },
};
const state = reactive(raw);
console.log(`proxies-before-nested=${created}`);
assert.equal(created, 1);
assert.equal(state.nested, state.nested);
assert.equal(reactive(state), state);
console.log(`proxies-after-nested=${created}`);
state.count = 2;
state.nested.value = 20;
console.log(`count=${state.count} nested=${state.nested.value}`);
assert.equal(raw.nested.value, 20);

const child = Object.create(state);
child.count = 7;
console.log(`receiver-get=${child.doubled}`);
child.doubled = 18;
console.log(`receiver-set=${child.count} parent=${state.count}`);
assert.equal(child.count, 9);
assert.equal(state.count, 2);
JS
node "$work/main.js"
