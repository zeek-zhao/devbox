// 六条安全默认的回归守卫。每一条都要有对应用例 —— 少一条，工具就可能在别人的仓库里出事。
import test from 'node:test';
import assert from 'node:assert/strict';
import { parseArgs } from '../src/cli.js';

test('默认 dry-run（没有 --write 就是预览）', () => {
  assert.equal(parseArgs([]).write, false);
});

test('--write 才落盘', () => {
  assert.equal(parseArgs(['--write']).write, true);
});

test('受保护分支需要显式授权', () => {
  const o = parseArgs(['--allow-branch', 'main']);
  assert.deepEqual(o.allowBranches, ['main']);
});

test('未知参数直接报错，不静默忽略', () => {
  assert.throws(() => parseArgs(['--force']));
});

test('--release-as 只接受合法值', () => {
  assert.throws(() => parseArgs(['--release-as', 'huge']));
  assert.equal(parseArgs(['--release-as', 'minor']).releaseAs, 'minor');
  assert.equal(parseArgs(['--release-as', '1.2.3']).releaseAs, '1.2.3');
});
