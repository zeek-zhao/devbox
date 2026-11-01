#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-008-debounce-search"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, h, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

function debounce(callback, delay) {
  let timer;
  function debounced(...args) {
    clearTimeout(timer);
    timer = setTimeout(() => {
      timer = undefined;
      callback.apply(this, args);
    }, delay);
  }
  debounced.cancel = () => {
    clearTimeout(timer);
    timer = undefined;
  };
  return debounced;
}

async function main() {
  let queries = 0;
  const result = ref('');
  const search = debounce((query) => {
    queries++;
    result.value = query;
  }, 5);
  const inputs = ['v', 'vu', 'vue', 'vue3', 'vue3 ssr'];
  for (const input of inputs) search(input);
  console.log(`inputs=${inputs.length} before-wait=${queries}`);
  await new Promise((resolve) => setTimeout(resolve, 20));
  console.log(`queries=${queries} last=${result.value}`);
  assert.equal(queries, 1);
  assert.equal(result.value, inputs.at(-1));
  const View = { setup: () => () => h('p', `Results: ${result.value}`) };
  console.log(await renderToString(createSSRApp(View)));
  search('cancelled');
  search.cancel();
  await new Promise((resolve) => setTimeout(resolve, 20));
  console.log(`after-cancel=${queries}`);
  assert.equal(queries, 1);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
