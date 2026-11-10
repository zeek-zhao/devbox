'use strict';

const assert = require('node:assert/strict');

// 错误匹配：拿到错误后按「错误身份」匹配处理策略——
// instanceof 定类型、code 定分支，而不是解析 message 文本。
class AppError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'AppError';
    this.code = code;
  }
}

function strategyFor(error) {
  if (!(error instanceof AppError)) {
    return 'report';
  }
  if (error.code === 'E_NETWORK') {
    return 'retry';
  }
  if (error.code === 'E_REQUIRED' || error.code === 'E_RANGE') {
    return 'fix-input';
  }
  return 'report';
}

function load(source) {
  if (source === 'network') {
    throw new AppError('E_NETWORK', 'request failed');
  }
  if (source === 'required') {
    throw new AppError('E_REQUIRED', 'query is required');
  }
  if (source === 'range') {
    throw new AppError('E_RANGE', 'page out of range');
  }
  throw new Error('something else');
}

function handle(source) {
  try {
    load(source);
    return 'none';
  } catch (err) {
    return strategyFor(err);
  }
}

async function main() {
  assert.equal(handle('network'), 'retry');
  assert.equal(handle('required'), 'fix-input');
  assert.equal(handle('range'), 'fix-input');
  assert.equal(handle('other'), 'report');
  console.log('matched=E_NETWORK action=retry');
  console.log('matched=E_REQUIRED action=fix-input');
  console.log('matched=E_RANGE action=fix-input');
  console.log('matched=plain-error action=report');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
