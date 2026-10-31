#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-015-plugin-install"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const plugin = {
  install(app) {
    app.config.globalProperties.$badge = 'plugin ready';
  },
};
const App = {
  render() {
    return h('p', this.$badge);
  },
};
const app = createSSRApp(App);
app.use(plugin);

renderToString(app).then((html) => {
  console.log(html);
});
NODE

node "$TMP_DIR/app.js"
