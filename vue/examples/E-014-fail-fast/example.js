'use strict';

const assert = require('node:assert/strict');
const { createSSRApp, h } = require('vue');

// 快速失败：应用启动前集中校验必需环境（API 地址、令牌），
// 第一个缺失即停；对照不做校验——应用带病启动，失败发生在用户眼前。
class AppError extends Error {
  constructor(code, field, message) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.field = field;
  }
}

const REQUIRED_ENV_KEYS = ['DEVBOX_API_URL', 'DEVBOX_TOKEN'];

function validateEnv(env) {
  for (const key of REQUIRED_ENV_KEYS) {
    if (!env[key]) {
      throw new AppError('E_ENV_REQUIRED', key, `missing ${key}`);
    }
  }
}

function createAppFromEnv(env) {
  validateEnv(env);
  return createSSRApp({ render: () => h('p', 'ready') });
}

async function main() {
  try {
    createAppFromEnv({ DEVBOX_TOKEN: 'token-1' });
  } catch (err) {
    assert.equal(err.code, 'E_ENV_REQUIRED');
    assert.equal(err.field, 'DEVBOX_API_URL');
    console.log(`env missing: created=false code=${err.code} field=${err.field}`);
  }

  const app = createAppFromEnv({
    DEVBOX_API_URL: 'https://example.invalid',
    DEVBOX_TOKEN: 'token-1',
  });
  assert.ok(app);
  console.log('env ok: created=true');
  console.log('fail-fast checks=2');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
