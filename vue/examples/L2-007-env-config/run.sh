#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-007-env-config"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cat >"$TMP_DIR/app.js" <<'NODE'
const mode = process.env.APP_MODE;
if (mode !== 'a' && mode !== 'b') {
  throw new Error(`unsupported APP_MODE: ${mode}`);
}
console.log(mode === 'a' ? '<p>alpha</p>' : '<p>beta</p>');
NODE

APP_MODE=a node "$TMP_DIR/app.js"
APP_MODE=b node "$TMP_DIR/app.js"
