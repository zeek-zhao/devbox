'use strict';

const assert = require('node:assert/strict');

// 错误包装：底层错误（SyntaxError）不该裸奔到 UI 层——
// 包装成带组件上下文的新错误，原错误挂进 cause，链上每层都还在。
function parsePayload(raw) {
  try {
    return JSON.parse(raw);
  } catch (err) {
    throw new Error('component Card: parse payload failed', { cause: err });
  }
}

function loadCard(store) {
  try {
    return parsePayload(store);
  } catch (err) {
    throw new Error('component Page: load card failed', { cause: err });
  }
}

async function main() {
  try {
    loadCard('{bad');
  } catch (err) {
    assert.equal(err.message, 'component Page: load card failed');
    assert.ok(err.cause instanceof Error);
    assert.equal(err.cause.message, 'component Card: parse payload failed');
    assert.ok(err.cause.cause instanceof SyntaxError);
    console.log(`wrapped=${err.message}`);
    console.log(`cause level1=${err.cause.message}`);
    console.log(`cause level2=${err.cause.cause.name}`);
    console.log(`cause is SyntaxError=${err.cause.cause instanceof SyntaxError}`);
    console.log('chain depth=3');
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
