#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-006-package-exports"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR/node_modules/exports-example"

cat >"$TMP_DIR/node_modules/exports-example/package.json" <<'JSON'
{
  "name": "exports-example",
  "exports": {
    ".": "./index.js",
    "./safe": "./safe.js"
  }
}
JSON

printf '%s\n' "module.exports = 'package entry';" >"$TMP_DIR/node_modules/exports-example/index.js"
printf '%s\n' "module.exports = 'safe subpath';" >"$TMP_DIR/node_modules/exports-example/safe.js"
printf '%s\n' "module.exports = 'private subpath';" >"$TMP_DIR/node_modules/exports-example/private.js"

cat >"$TMP_DIR/main.js" <<'NODE'
console.log(`package: ${require('exports-example')}`);
console.log(`safe subpath: ${require('exports-example/safe')}`);
try {
  require('exports-example/private');
  throw new Error('private subpath unexpectedly loaded');
} catch (error) {
  if (error.code !== 'ERR_PACKAGE_PATH_NOT_EXPORTED') {
    throw error;
  }
  console.log('private subpath: blocked');
}
NODE

node "$TMP_DIR/main.js"
