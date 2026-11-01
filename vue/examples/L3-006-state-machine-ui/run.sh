#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-006-state-machine-ui"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, h, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const transitions = Object.freeze({
  idle: Object.freeze({ start: 'loading' }),
  loading: Object.freeze({ resolve: 'done', reject: 'error' }),
  done: Object.freeze({ reset: 'idle' }),
  error: Object.freeze({ retry: 'loading' }),
});
const state = ref('idle');
function dispatch(event) {
  const from = state.value;
  const next = Object.hasOwn(transitions[from], event) ? transitions[from][event] : undefined;
  if (!next) {
    console.log(
      `rejected: ${from} + ${event}; allowed=${Object.keys(transitions[from]).join(',')}`,
    );
    return false;
  }
  state.value = next;
  console.log(`transition: ${from} + ${event} -> ${next}`);
  return true;
}
const View = {
  setup() {
    return () => h('p', { 'data-state': state.value }, state.value);
  },
};

async function main() {
  for (const [from, events] of Object.entries(transitions)) {
    console.log(`table: ${from} ${JSON.stringify(events)}`);
  }
  console.log(await renderToString(createSSRApp(View)));
  assert.equal(dispatch('resolve'), false);
  assert.equal(state.value, 'idle');
  for (const event of ['start', 'reject', 'retry', 'resolve', 'reset']) {
    assert.equal(dispatch(event), true);
    console.log(await renderToString(createSSRApp(View)));
  }
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
