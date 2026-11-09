'use strict';

const assert = require('node:assert/strict');

// 错误身份：同一个错误对象从最底层穿到最上层，引用与 instanceof 身份必须不变；
// 任何一层 new Error(err.message) 重新包装，身份就断了——
// 上层按类型/code 建立的分派（E-003）从此命不中。
class ServiceError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'ServiceError';
    this.code = code;
  }
}

let lastThrown = null;

function lowLevel() {
  const err = new ServiceError('E_DB_DOWN', 'database unavailable');
  lastThrown = err;
  throw err;
}

function composable() {
  lowLevel();
}

function capture(fn) {
  try {
    fn();
  } catch (err) {
    return err;
  }
  return null;
}

async function main() {
  const original = capture(() => composable());
  assert.ok(original instanceof ServiceError);
  assert.equal(original.code, 'E_DB_DOWN');

  const rewrapped = new Error(original.message);

  console.log(`identity through chain: same=${original === lastThrown}`);
  console.log(`code survives chain: ${original.code}`);
  console.log(`identity after rewrap: same=${rewrapped === original}`);
  console.log(`instanceof after rewrap: ${rewrapped instanceof ServiceError}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
