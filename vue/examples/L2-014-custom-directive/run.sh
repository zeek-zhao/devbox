#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-014-custom-directive"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const { createSSRApp, h, withDirectives } = require('vue');
const { renderToString } = require('@vue/server-renderer');

let mounted = false;
const focus = {
  mounted() {
    mounted = true;
  },
};
const App = {
  render() {
    return withDirectives(h('input'), [[focus]]);
  },
};

renderToString(createSSRApp(App)).then((html) => {
  console.log(`mounted hook called: ${mounted}`);
  console.log(`directive attribute: ${/v-focus/.test(html) ? 'present' : 'absent'}`);
});
NODE

node "$TMP_DIR/app.js"
