'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

async function main() {
  const TreeNode = {
    name: 'TreeNode',
    props: { node: { type: Object, required: true } },
    setup(props) {
      return () =>
        h('li', { 'data-name': props.node.name }, [
          props.node.name,
          props.node.children.length
            ? h(
                'ul',
                props.node.children.map((child) => h(TreeNode, { key: child.name, node: child })),
              )
            : null,
        ]);
    },
  };
  const tree = {
    name: 'root',
    children: [{ name: 'leaf', children: [] }],
  };
  const html = await renderToString(createSSRApp({ render: () => h(TreeNode, { node: tree }) }));
  assert.equal((html.match(/<li/g) || []).length, 2);
  assert.ok(html.includes('data-name="leaf"'));
  console.log(
    `nodes=${(html.match(/<li/g) || []).length} leaf=${html.includes('data-name="leaf"')}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
