#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-010-teleport"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const { createSSRApp, h, Teleport } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const App = {
  render() {
    return h(Teleport, { to: '#target' }, [h('span', 'teleported')]);
  },
};
const context = {};

renderToString(createSSRApp(App), context).then((html) => {
  console.log(
    `teleport marker: ${html.includes('<!--teleport start-->') ? 'present' : 'missing'}`,
  );
  console.log(`target content: ${context.teleports['#target']}`);
});
NODE

node "$TMP_DIR/app.js"
