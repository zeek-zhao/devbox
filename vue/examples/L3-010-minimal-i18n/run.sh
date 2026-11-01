#!/usr/bin/env bash
set -euo pipefail

work="${TMPDIR:-/tmp}/devbox-L3-010-minimal-i18n"
rm -rf -- "$work"
mkdir -p -- "$work"
trap 'rm -rf -- "$work"' EXIT

cat > "$work/main.js" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');
const { renderToString } = require('@vue/server-renderer');

const dictionaries = {
  en: { greeting: 'Hello, {name}! Welcome, {name}.' },
  zh: { greeting: '你好，{name}！欢迎，{name}。' },
};
function translate(locale, key, params) {
  if (!Object.hasOwn(dictionaries, locale) || !Object.hasOwn(dictionaries[locale], key)) {
    throw new Error(`Missing translation: ${locale}.${key}`);
  }
  return dictionaries[locale][key].replace(/\{(\w+)\}/g, (match, name) => {
    if (!Object.hasOwn(params, name)) throw new Error(`Missing parameter: ${name}`);
    return String(params[name]);
  });
}
const View = {
  props: { locale: { type: String, required: true } },
  setup(props) {
    return () =>
      h('p', { lang: props.locale }, translate(props.locale, 'greeting', { name: 'Ada' }));
  },
};

async function main() {
  for (const locale of ['en', 'zh']) {
    console.log(await renderToString(createSSRApp(View, { locale })));
  }
  assert.throws(() => translate('fr', 'greeting', {}), /Missing translation/);
  assert.throws(() => translate('en', 'greeting', {}), /Missing parameter/);
  assert.equal(translate('en', 'greeting', { name: '$&' }), 'Hello, $&! Welcome, $&.');
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
JS
node "$work/main.js"
