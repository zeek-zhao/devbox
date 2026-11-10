'use strict';

const assert = require('node:assert/strict');
const { computed, nextTick, reactive, watchEffect } = require('vue');

// 反模式对照：把 E 段与 S 系素材踩过的前端坑集中成可跑的对照实验——
// 每一行 bad= 都是坏写法的真实现象，good= 是同场景的正确写法。
async function main() {
  // 对照一：解构 reactive 丢失响应性（响应性丢失，S 系）。
  const state = reactive({ count: 1 });
  const { count } = state;
  let seenDestructured = 0;
  let seenReactive = 0;
  watchEffect(() => {
    seenDestructured = count;
  });
  watchEffect(() => {
    seenReactive = state.count;
  });
  state.count = 2;
  await nextTick();
  assert.equal(seenDestructured, 1);
  assert.equal(seenReactive, 2);
  console.log(`antipattern=destructuring bad=${seenDestructured} good=${seenReactive}`);

  // 对照二：子组件直接改 props（单向数据流破坏）vs 改本地副本 + 交还。
  const parentState = reactive({ count: 1 });
  const propPassedToChild = parentState;
  propPassedToChild.count = 99;
  assert.equal(parentState.count, 99);
  parentState.count = 1;
  const childLocalCopy = { ...parentState };
  childLocalCopy.count = 42;
  assert.equal(parentState.count, 1);
  console.log(`antipattern=mutate-prop bad=parent=99 good=parent-with-copy=1`);

  // 对照三：吞掉 Promise 失败 vs 显式接住并记录。
  async function failingLoad() {
    throw new Error('network down');
  }
  let recorded = 0;
  failingLoad().catch(() => {});
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(recorded, 0);
  failingLoad().catch(() => {
    recorded++;
  });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(recorded, 1);
  console.log(`antipattern=swallowed-promise bad=recorded=0 good=recorded=1`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
