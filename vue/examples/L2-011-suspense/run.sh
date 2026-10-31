#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-011-suspense"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const { createSSRApp, h, Suspense } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const AsyncChild = {
  async setup() {
    await Promise.resolve();
    return () => h('p', 'resolved content');
  },
};
const App = {
  render() {
    return h(Suspense, null, {
      default: () => h(AsyncChild),
      fallback: () => h('p', 'loading fallback'),
    });
  },
};

renderToString(createSSRApp(App)).then((html) => {
  console.log(`fallback: ${html.includes('loading fallback') ? 'present' : 'absent'}`);
  console.log(`final content: ${html.includes('resolved content') ? 'present' : 'absent'}`);
});
NODE

node "$TMP_DIR/app.js"
