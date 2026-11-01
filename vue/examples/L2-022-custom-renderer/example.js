'use strict';

const assert = require('node:assert/strict');
const { createRenderer, h } = require('vue');

function createNode(type, text = '') {
  return { type, text, props: {}, children: [], parent: null };
}
const renderer = createRenderer({
  createElement: (type) => createNode(type),
  createText: (text) => createNode('#text', text),
  createComment: (text) => createNode('#comment', text),
  setText: (node, text) => {
    node.text = text;
  },
  setElementText: (node, text) => {
    node.children = [];
    node.text = text;
  },
  patchProp: (node, key, _oldValue, value) => {
    node.props[key] = value;
  },
  insert: (node, parent, anchor = null) => {
    node.parent = parent;
    const index = anchor ? parent.children.indexOf(anchor) : -1;
    parent.children.splice(index < 0 ? parent.children.length : index, 0, node);
  },
  remove: (node) => {
    if (node.parent) {
      node.parent.children.splice(node.parent.children.indexOf(node), 1);
      node.parent = null;
    }
  },
  parentNode: (node) => node.parent,
  nextSibling: (node) => {
    if (!node.parent) return null;
    return node.parent.children[node.parent.children.indexOf(node) + 1] || null;
  },
});
const root = createNode('root');
renderer
  .createApp({
    render: () => h('ul', [h('li', { id: 'first' }, 'one')]),
  })
  .mount(root);

assert.equal(root.children[0].type, 'ul');
assert.equal(root.children[0].children[0].text, 'one');
assert.equal(root.children[0].children[0].props.id, 'first');
console.log('tree=ul>li#first:one');
