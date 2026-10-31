import test from 'node:test';
import assert from 'node:assert/strict';
import { renderSection } from '../src/changelog.js';

const types = [
  { type: 'feat', section: '✨ Features | 新功能' },
  { type: 'fix', section: '🐛 Bug Fixes | Bug 修复' },
  { type: 'chore', section: '🚀 Chore', hidden: true },
];

test('按 section 分组', () => {
  const md = renderSection('1.1.0', [
    { type: 'fix', scope: 'db', subject: '修连接' },
    { type: 'feat', scope: null, subject: '加轨道' },
  ], { types, date: '2026-11-01' });
  assert.match(md, /✨ Features/);
  assert.match(md, /🐛 Bug Fixes/);
  assert.match(md, /\*\*db\*\*: 修连接|\*\*db\*\* 修连接/);
});

test('hidden 类型不出现', () => {
  const md = renderSection('1.1.0', [{ type: 'chore', subject: '杂活' }], { types, date: '2026-11-01' });
  assert.doesNotMatch(md, /杂活/);
});

test('渲染是确定的：同样输入两次输出一致', () => {
  const commits = [
    { type: 'fix', scope: 'b', subject: '二' },
    { type: 'fix', scope: 'a', subject: '一' },
  ];
  const a = renderSection('1.1.0', commits, { types, date: '2026-11-01' });
  const b = renderSection('1.1.0', [...commits].reverse(), { types, date: '2026-11-01' });
  assert.equal(a, b);
});

test('breaking 单独一节且在最前', () => {
  const md = renderSection('2.0.0', [
    { type: 'feat', subject: '改行为', breaking: true },
    { type: 'fix', subject: '小修' },
  ], { types, date: '2026-11-01' });
  assert.ok(md.indexOf('Breaking') < md.indexOf('Bug Fixes'));
});
