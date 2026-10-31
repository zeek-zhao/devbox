#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-012-keep-alive"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const { createSSRApp, h, KeepAlive } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const Child = { render: () => h('p', 'keep-alive child') };
const App = {
  render() {
    return h(KeepAlive, null, {
      default: () => h(Child),
    });
  },
};

renderToString(createSSRApp(App)).then((html) => {
  console.log(html);
});
NODE

node "$TMP_DIR/app.js"
