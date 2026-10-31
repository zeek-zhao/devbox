#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-008-error-captured"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const { createSSRApp, h, onErrorCaptured } = require('vue');
const { renderToString } = require('@vue/server-renderer');

let captured = '';
const Child = {
  setup() {
    throw new Error('child setup failed');
  },
};
const Parent = {
  setup() {
    onErrorCaptured((error) => {
      captured = error.message;
      return false;
    });
    return () => h(Child);
  },
};

renderToString(createSSRApp(Parent))
  .then(() => {
    console.log(`captured: ${captured}`);
  })
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
NODE

node "$TMP_DIR/app.js"
