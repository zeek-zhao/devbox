'use strict';

const assert = require('node:assert/strict');

// 超时与截止：对每个异步数据源设截止时间。Promise.race 让加载与定时器赛跑，
// 到点后返回 { timedOut: true }，定时器必须清理（不清理就是泄漏）。
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function withDeadline(promise, ms) {
  let timer;
  const deadline = new Promise((resolve) => {
    timer = setTimeout(() => resolve({ timedOut: true, value: null }), ms);
  });
  try {
    return await Promise.race([promise.then((value) => ({ timedOut: false, value })), deadline]);
  } finally {
    clearTimeout(timer);
  }
}

async function fastLoad() {
  return 'data';
}

function hungLoad() {
  return new Promise(() => {});
}

async function main() {
  const fast = await withDeadline(fastLoad(), 50);
  assert.equal(fast.timedOut, false);
  console.log(`load fast: result=${fast.value}`);

  const hung = await withDeadline(hungLoad(), 50);
  assert.equal(hung.timedOut, true);
  console.log('load hung: result=E_TIMEOUT after 50ms');
  console.log('deadline conversions=1');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
