#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-004-async-data-state"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, h, reactive } = require('vue');
const { renderToString } = require('@vue/server-renderer');

function useAsyncData() {
  const state = reactive({ status: 'idle', items: [], error: '' });
  async function load(request) {
    state.status = 'loading';
    state.error = '';
    state.items = [];
    try {
      state.items = await request();
      state.status = state.items.length ? 'done' : 'empty';
    } catch (error) {
      state.error = error.message;
      state.status = 'error';
    }
  }
  return { state, load };
}

async function main() {
  const { state, load } = useAsyncData();
  const View = {
    setup() {
      return () => {
        switch (state.status) {
          case 'loading':
            return h('p', { 'data-state': state.status }, 'Loading');
          case 'error':
            return h('p', { 'data-state': state.status }, `Error: ${state.error}`);
          case 'empty':
            return h('p', { 'data-state': state.status }, 'No results');
          case 'done':
            return h(
              'ul',
              state.items.map((item) => h('li', item)),
            );
          default:
            return h('p', 'Idle');
        }
      };
    },
  };
  let rejectRequest;
  const request = new Promise((resolve, reject) => {
    rejectRequest = reject;
  });
  const loading = load(() => request);
  console.log(await renderToString(createSSRApp(View)));
  rejectRequest(new Error('offline'));
  await loading;
  assert.equal(state.status, 'error');
  console.log(await renderToString(createSSRApp(View)));
  await load(() => Promise.resolve([]));
  assert.equal(state.status, 'empty');
  assert.equal(state.error, '');
  console.log(await renderToString(createSSRApp(View)));
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
