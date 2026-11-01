#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-003-hydration-mismatch"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const View = {
  props: { client: Boolean },
  setup(props) {
    return () => h('p', `value:${props.client ? 'client-fixed' : 'server-fixed'}`);
  },
};

async function main() {
  const server = await renderToString(createSSRApp(View, { client: false }));
  const client = await renderToString(createSSRApp(View, { client: true }));
  let index = 0;
  while (index < Math.min(server.length, client.length) && server[index] === client[index]) {
    index++;
  }
  assert.notEqual(server, client);
  console.log(`server=${server}`);
  console.log(`client-first=${client}`);
  console.log(`first-difference=${index} server=${server[index]} client=${client[index]}`);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
