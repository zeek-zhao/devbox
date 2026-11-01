#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-013-transition-hooks"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const { createSSRApp, h, Transition } = require('vue');
const { renderToString } = require('@vue/server-renderer');

let entered = false;
const App = {
  render() {
    return h(Transition, { onEnter: () => (entered = true) }, {
      default: () => h('p', 'transition child'),
    });
  },
};

renderToString(createSSRApp(App)).then(() => {
  console.log(`onEnter called: ${entered}`);
});
NODE

node "$TMP_DIR/app.js"
