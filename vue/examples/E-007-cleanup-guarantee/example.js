'use strict';

const assert = require('node:assert/strict');
const { effectScope, nextTick, ref, watchEffect } = require('vue');

// 清理保证：副作用（订阅/定时器/请求）注册时必须同时注册清理——
// watch 的 onCleanup 在「重新执行前」和「作用域停止时」都会被调用，
// 两条路径都不清理就会泄漏旧订阅。
async function main() {
  const query = ref('a');
  let runs = 0;
  let cleanups = 0;
  const scope = effectScope();

  scope.run(() => {
    watchEffect((onCleanup) => {
      const value = query.value;
      runs++;
      onCleanup(() => {
        cleanups++;
      });
    });
  });

  query.value = 'b';
  await nextTick();
  assert.equal(runs, 2);
  assert.equal(cleanups, 1);
  console.log(`runs=2 cleanups=1 (invalidation cleanup ran)`);

  scope.stop();
  query.value = 'c';
  await nextTick();
  assert.equal(runs, 2);
  assert.equal(cleanups, 2);
  console.log(`scope stopped: runs=2 cleanups=2`);
  console.log('cleanup on invalidation: true');
  console.log('cleanup on stop: true');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
