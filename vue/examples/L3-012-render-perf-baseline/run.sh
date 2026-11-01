#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-012-render-perf-baseline"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { performance } = require('node:perf_hooks');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const View = {
  props: { count: { type: Number, required: true } },
  setup(props) {
    return () => h('p', `count:${props.count}`);
  },
};

async function main() {
  const iterations = 1000;
  let rendered = 0;
  let totalBytes = 0;
  const start = performance.now();
  for (let count = 0; count < iterations; count++) {
    const html = await renderToString(createSSRApp(View, { count }));
    assert.equal(html, `<p>count:${count}</p>`);
    totalBytes += Buffer.byteLength(html);
    rendered++;
  }
  const elapsed = performance.now() - start;
  console.log(`renders=${rendered} bytes=${totalBytes}`);
  console.log(`total-time=${elapsed < 1000 ? '<1s' : '>=1s'}`);
  assert.equal(rendered, iterations);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
