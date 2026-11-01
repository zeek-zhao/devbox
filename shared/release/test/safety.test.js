// 六条安全默认的回归守卫。每一条都要有对应用例 —— 少一条，工具就可能在别人的仓库里出事。
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { parseArgs } from '../src/cli.js';
import { validateConfig } from '../src/config.js';
import * as gitApi from '../src/git.js';

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
  assert.throws(() => parseArgs(['--release-as', '1.2.3-']));
  assert.throws(() => parseArgs(['--release-as', '1.2.3-01']));
  assert.equal(parseArgs(['--release-as', 'minor']).releaseAs, 'minor');
  assert.equal(parseArgs(['--release-as', '1.2.3']).releaseAs, '1.2.3');
});

test('配置错误指出具体白名单项', () => {
  assert.throws(() => validateConfig({
    versionFiles: [{ path: 'VERSION', kind: 'bad' }],
    types: [],
    protectedBranches: [],
  }), /versionFiles\[0\]\.kind/);
});

test('git 封装不暴露 push 操作', () => {
  assert.equal(Object.hasOwn(gitApi, 'push'), false);
});

test('依赖为空且源码没有网络/API 调用入口', () => {
  const packageJson = JSON.parse(fs.readFileSync(new URL('../package.json', import.meta.url), 'utf8'));
  assert.ok(!packageJson.dependencies || Object.keys(packageJson.dependencies).length === 0);
  const source = fs.readdirSync(new URL('../src/', import.meta.url))
    .filter((name) => name.endsWith('.js'))
    .map((name) => fs.readFileSync(new URL(`../src/${name}`, import.meta.url), 'utf8'))
    .join('\n');
  assert.doesNotMatch(source, /node:(?:http|https)|\bfetch\s*\(|\bhttps?\.request\s*\(/);
});
