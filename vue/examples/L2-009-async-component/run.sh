#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-009-async-component"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const { createSSRApp, defineAsyncComponent, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

let loaded = false;
const AsyncChild = defineAsyncComponent(() =>
  Promise.resolve().then(() => {
    loaded = true;
    return { render: () => h('p', 'async ready') };
  }),
);
const App = { render: () => h(AsyncChild) };

console.log(`before: ${loaded ? 'loaded' : 'not loaded'}`);
renderToString(createSSRApp(App)).then((html) => {
  console.log(`after: ${loaded ? 'loaded' : 'not loaded'}`);
  console.log(html);
});
NODE

node "$TMP_DIR/app.js"
