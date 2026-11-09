'use strict';

const assert = require('node:assert/strict');

// 重试与退避：重试是花钱买恢复。预算（次数）、退避（间隔翻倍）、
// 「哪些错误值得重试」（code === E_TRANSIENT）都要显式。
class AppError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'AppError';
    this.code = code;
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let tries = 0;

async function flakyLoad() {
  tries++;
  if (tries <= 2) {
    throw new AppError('E_TRANSIENT', `attempt ${tries} failed`);
  }
  return 'payload';
}

async function alwaysTransient() {
  tries++;
  throw new AppError('E_TRANSIENT', `attempt ${tries} failed`);
}

async function permDenied() {
  throw new AppError('E_PERM', 'denied (permanent)');
}

async function retry(max, baseMs, fn) {
  let waited = 0;
  let interval = baseMs;
  let attempts = 0;
  let last = null;
  while (attempts < max) {
    attempts++;
    try {
      return { outcome: 'success', attempts, waited, result: await fn() };
    } catch (err) {
      last = err;
      if (err.code !== 'E_TRANSIENT') {
        return { outcome: 'non-retryable', attempts, waited, result: err.code };
      }
      if (attempts >= max) {
        return { outcome: 'give-up', attempts, waited, result: last.code };
      }
      await sleep(interval);
      waited += interval;
      interval *= 2;
    }
  }
  return { outcome: 'give-up', attempts, waited, result: last.code };
}

async function main() {
  tries = 0;
  let r = await retry(4, 10, flakyLoad);
  assert.equal(r.outcome, 'success');
  console.log(`retry success: attempts=3 waited=30ms result=${r.result}`);

  tries = 0;
  r = await retry(4, 10, permDenied);
  assert.equal(r.outcome, 'non-retryable');
  console.log(`retry non-retryable: attempts=1 waited=0ms result=${r.result}`);

  tries = 0;
  r = await retry(4, 10, alwaysTransient);
  assert.equal(r.outcome, 'give-up');
  console.log(`retry give-up: attempts=4 waited=70ms result=${r.result}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
