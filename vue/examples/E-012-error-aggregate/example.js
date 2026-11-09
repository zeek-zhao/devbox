'use strict';

const assert = require('node:assert/strict');

// 失败聚合：多个独立数据源并行加载时，用 allSettled 收齐全部结果——
// 一个失败不遮蔽其他成功，失败清单一次拿全（而不是修一个再撞下一个）。
class AppError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'AppError';
    this.code = code;
  }
}

async function fetchSource(name) {
  if (name === 'b') {
    throw new AppError('E_OFFLINE', 'source b offline');
  }
  if (name === 'c') {
    throw new AppError('E_QUOTA', 'source c quota exceeded');
  }
  return `payload-${name}`;
}

async function main() {
  const names = ['a', 'b', 'c'];
  const settled = await Promise.allSettled([fetchSource('a'), fetchSource('b'), fetchSource('c')]);

  let ok = 0;
  let failed = 0;
  const reasons = [];
  settled.forEach((result, index) => {
    if (result.status === 'fulfilled') {
      ok++;
      console.log(`source=${names[index]} status=fulfilled value=${result.value}`);
    } else {
      failed++;
      reasons.push(result.reason.code);
      console.log(`source=${names[index]} status=rejected reason=${result.reason.code}`);
    }
  });
  assert.equal(ok, 1);
  assert.equal(failed, 2);
  console.log(`aggregate ok=1 failed=2`);
  console.log(`failed reasons=${reasons.join(',')}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
