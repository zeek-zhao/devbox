#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-011-theme-tokens"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, h, provide, inject } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const themeKey = Symbol('theme');
const themes = Object.freeze({
  light: Object.freeze({ foreground: '#111', background: '#fff', spacing: '8px' }),
  dark: Object.freeze({ foreground: '#eee', background: '#222', spacing: '8px' }),
});
const Button = {
  setup() {
    const tokens = inject(themeKey);
    if (!tokens) throw new Error('Theme provider is missing');
    assert.equal(Object.isFrozen(tokens), true);
    assert.throws(() => {
      tokens.foreground = 'red';
    }, TypeError);
    return () =>
      h(
        'button',
        {
          style: {
            color: tokens.foreground,
            backgroundColor: tokens.background,
            padding: tokens.spacing,
          },
        },
        'Theme',
      );
  },
};
const Provider = {
  props: { theme: { type: String, required: true } },
  setup(props) {
    if (!Object.hasOwn(themes, props.theme)) throw new Error(`Unknown theme: ${props.theme}`);
    provide(themeKey, themes[props.theme]);
    return () => h(Button);
  },
};

async function main() {
  for (const theme of ['light', 'dark']) {
    console.log(`${theme}=${await renderToString(createSSRApp(Provider, { theme }))}`);
  }
  console.log(`tokens-frozen=${Object.values(themes).every(Object.isFrozen)}`);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
