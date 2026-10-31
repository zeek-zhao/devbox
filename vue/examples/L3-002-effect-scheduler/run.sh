#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-002-effect-scheduler"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const dependencies = new WeakMap();
const jobs = new Set();
let activeEffect;
let pending;

function queueJob(job) {
  jobs.add(job);
  if (!pending) {
    pending = Promise.resolve().then(() => {
      try {
        while (jobs.size) {
          const batch = [...jobs];
          jobs.clear();
          for (const run of batch) run();
        }
      } finally {
        pending = undefined;
      }
    });
  }
}

function effect(callback) {
  function run() {
    for (const dep of run.deps) dep.delete(run);
    run.deps.clear();
    const previous = activeEffect;
    activeEffect = run;
    try {
      callback();
    } finally {
      activeEffect = previous;
    }
  }
  run.deps = new Set();
  run();
  return run;
}

function reactive(target) {
  return new Proxy(target, {
    get(object, key, receiver) {
      if (activeEffect) {
        let keys = dependencies.get(object);
        if (!keys) dependencies.set(object, (keys = new Map()));
        let dep = keys.get(key);
        if (!dep) keys.set(key, (dep = new Set()));
        dep.add(activeEffect);
        activeEffect.deps.add(dep);
      }
      return Reflect.get(object, key, receiver);
    },
    set(object, key, value, receiver) {
      const previous = Reflect.get(object, key, receiver);
      const success = Reflect.set(object, key, value, receiver);
      if (success && !Object.is(previous, value)) {
        const dep = dependencies.get(object)?.get(key);
        if (dep) {
          for (const run of [...dep]) {
            if (run !== activeEffect) queueJob(run);
          }
        }
      }
      return success;
    },
  });
}

async function main() {
  const state = reactive({ count: 0, enabled: true });
  let runs = 0;
  let observed;
  effect(() => {
    runs++;
    observed = state.enabled ? state.count : 'off';
  });
  const initial = runs;
  state.count = 1;
  state.count = 2;
  state.count = 3;
  console.log(`before-flush=${runs} value=${observed}`);
  await pending;
  console.log(`batch-effects=${runs - initial} total=${runs} value=${observed}`);
  assert.equal(runs - initial, 1);
  assert.equal(observed, 3);
  state.enabled = false;
  await pending;
  const disabledRuns = runs;
  state.count = 4;
  await Promise.resolve();
  console.log(`inactive-dependency-effects=${runs - disabledRuns} value=${observed}`);
  assert.equal(runs, disabledRuns);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
