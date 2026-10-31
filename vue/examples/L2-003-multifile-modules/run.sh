#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-003-multifile-modules"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/format.js" <<'NODE'
module.exports = function formatMessage(name) {
  return `hello ${name}`;
};
NODE

cat >"$TMP_DIR/component.js" <<'NODE'
const { h } = require('vue');
const formatMessage = require('./format');

module.exports = {
  render() {
    return h('p', formatMessage('modules'));
  },
};
NODE

cat >"$TMP_DIR/main.js" <<'NODE'
const { createSSRApp } = require('vue');
const { renderToString } = require('@vue/server-renderer');
const Component = require('./component');

renderToString(createSSRApp(Component)).then((html) => {
  console.log(html);
});
NODE

node "$TMP_DIR/main.js"
