import test from 'node:test';
import assert from 'node:assert/strict';
import { parseCommit } from '../src/commits.js';

test('普通 feat', () => {
  const c = parseCommit('feat(db): 新增数据库轨道');
  assert.equal(c.type, 'feat');
  assert.equal(c.scope, 'db');
  assert.equal(c.subject, '新增数据库轨道');
  assert.equal(c.breaking, false);
});

test('无 scope', () => {
  const c = parseCommit('fix: 修正连接串');
  assert.equal(c.type, 'fix');
  assert.equal(c.scope, null);
});

test('feat! 是破坏性变更', () => {
  const c = parseCommit('feat(api)!: 改接口签名');
  assert.equal(c.breaking, true);
});

test('footer 里的 BREAKING CHANGE', () => {
  const c = parseCommit('feat: 改行为', 'BREAKING CHANGE: 返回值从 null 变成空数组');
  assert.equal(c.breaking, true);
});

test('merge commit 返回 null', () => {
  assert.equal(parseCommit("Merge branch 'feat/x' into main"), null);
});

test('没有 type 前缀的提交返回 null', () => {
  assert.equal(parseCommit('fix typo'), null);
  assert.equal(parseCommit('更新文档'), null);
});
