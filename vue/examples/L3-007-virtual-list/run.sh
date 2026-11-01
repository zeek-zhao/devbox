#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-007-virtual-list"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const items = Array.from({ length: 1000 }, (_, index) => ({ index, text: `row-${index}` }));
const height = 200;
const rowHeight = 20;
function windowFor(scrollTop) {
  const visibleCount = Math.ceil(height / rowHeight);
  const start = Math.max(
    0,
    Math.min(Math.floor(scrollTop / rowHeight), items.length - visibleCount),
  );
  return { start, rows: items.slice(start, start + visibleCount) };
}
const View = {
  props: { scrollTop: { type: Number, required: true } },
  setup(props) {
    return () => {
      const { start, rows } = windowFor(props.scrollTop);
      return h('div', { style: { height: `${height}px`, overflow: 'auto' } }, [
        h('div', { style: { height: `${items.length * rowHeight}px`, position: 'relative' } }, [
          h(
            'ul',
            {
              style: {
                position: 'absolute',
                top: `${start * rowHeight}px`,
                margin: '0',
                padding: '0',
                listStyle: 'none',
              },
            },
            rows.map((item) =>
              h(
                'li',
                { key: item.index, 'data-index': item.index, style: { height: `${rowHeight}px` } },
                item.text,
              ),
            ),
          ),
        ]),
      ]);
    };
  },
};

async function main() {
  console.log(`data=${items.length} viewport=${height} row-height=${rowHeight}`);
  for (const scrollTop of [0, 400, 20000]) {
    const html = await renderToString(createSSRApp(View, { scrollTop }));
    const indices = [...html.matchAll(/<li data-index="(\d+)"/g)].map((match) => Number(match[1]));
    assert.equal(indices.length, 10);
    assert.ok(html.includes('height:200px;overflow:auto;'));
    assert.ok(html.includes('height:20000px;position:relative;'));
    assert.equal(indices[0], windowFor(scrollTop).start);
    console.log(
      `scroll=${scrollTop} rendered=${indices.length} first=${indices[0]} last=${indices.at(-1)}`,
    );
  }
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
