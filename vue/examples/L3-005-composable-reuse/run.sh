#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-005-composable-reuse"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/counter-a.js" <<'JS'
'use strict';
const { h } = require('vue');
module.exports = (useCounter, states) => ({
  setup() {
    const counter = useCounter();
    states.a = counter;
    counter.increment();
    counter.increment();
    return () => h('p', `A:${counter.count.value}`);
  },
});
JS
cat > "$work/counter-b.js" <<'JS'
'use strict';
const { h } = require('vue');
module.exports = (useCounter, states) => ({
  setup() {
    const counter = useCounter();
    states.b = counter;
    return () => h('p', `B:${counter.count.value}`);
  },
});
JS
cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, ref } = require('vue');
const { renderToString } = require('@vue/server-renderer');

function useCounter() {
  const count = ref(0);
  return { count, increment: () => count.value++ };
}

async function main() {
  const states = {};
  const A = require('./counter-a')(useCounter, states);
  const B = require('./counter-b')(useCounter, states);
  console.log(await renderToString(createSSRApp(A)));
  console.log(await renderToString(createSSRApp(B)));
  assert.notEqual(states.a.count, states.b.count);
  states.b.increment();
  console.log(`after-B-increment A=${states.a.count.value} B=${states.b.count.value}`);
  assert.equal(states.a.count.value, 2);
  assert.equal(states.b.count.value, 1);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
