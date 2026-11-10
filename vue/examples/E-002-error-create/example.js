'use strict';

const assert = require('node:assert/strict');

// 错误创建：失败不是随手 throw new Error('bad')，而是带结构化元数据的领域错误：
// name 定位类型，code 对应处理策略，field 定位出问题的数据。
// 三个元数据一起构成可分派、可定位的错误。
class ValidationError extends Error {
  constructor(code, field, message) {
    super(message);
    this.name = 'ValidationError';
    this.code = code;
    this.field = field;
  }
}

function validateProfile(profile) {
  if (!profile.name) {
    throw new ValidationError('E_REQUIRED', 'name', 'name is required');
  }
  if (profile.age < 0 || profile.age > 150) {
    throw new ValidationError('E_RANGE', 'age', 'age out of range');
  }
  return true;
}

function describe(error) {
  assert.ok(error instanceof ValidationError);
  return `error=${error.name} code=${error.code} field=${error.field} message=${error.message}`;
}

async function main() {
  try {
    validateProfile({ name: '', age: 30 });
  } catch (err) {
    console.log(describe(err));
  }
  try {
    validateProfile({ name: 'devbox', age: 999 });
  } catch (err) {
    console.log(describe(err));
  }
  console.log('metadata fields=3 (code, field, message)');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
