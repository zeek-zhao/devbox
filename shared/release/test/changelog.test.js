import test from 'node:test';
import assert from 'node:assert/strict';
import { mergeChangelog, renderSection } from '../src/changelog.js';

const types = [
  { type: 'feat', section: '✨ Features | 新功能' },
  { type: 'fix', section: '🐛 Bug Fixes | Bug 修复' },
  { type: 'chore', section: '🚀 Chore', hidden: true },
];

test('按 section 分组', () => {
  const md = renderSection(
    '1.1.0',
    [
      { type: 'fix', scope: 'db', subject: '修连接' },
      { type: 'feat', scope: null, subject: '加轨道' },
    ],
    { types, date: '2026-11-01' },
  );
  assert.match(md, /✨ Features/);
  assert.match(md, /🐛 Bug Fixes/);
  assert.match(md, /\*\*db\*\*: 修连接|\*\*db\*\* 修连接/);
});

test('hidden 类型不出现', () => {
  const md = renderSection('1.1.0', [{ type: 'chore', subject: '杂活' }], {
    types,
    date: '2026-11-01',
  });
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
  const md = renderSection(
    '2.0.0',
    [
      { type: 'feat', subject: '改行为', breaking: true },
      { type: 'fix', subject: '小修' },
    ],
    { types, date: '2026-11-01' },
  );
  assert.ok(md.indexOf('Breaking') < md.indexOf('Bug Fixes'));
});

test('没有仓库 URL 时 CHANGELOG 标题为纯文本而非相对 compare 链接', () => {
  const md = renderSection('1.1.0', [], { types, date: '2026-11-01' });
  assert.ok(md.startsWith('## 1.1.0 (2026-11-01)\n'));
  assert.match(md, /^v1\.1\.0\^\.\.\.v1\.1\.0$/m);
  assert.doesNotMatch(md, /compare\//);
});

test('没有仓库 URL 时保留前一 tag 到新 tag 的纯文本范围', () => {
  const md = renderSection('0.1.0', [], {
    types,
    date: '2026-11-01',
    previousTag: 'v0.0.1',
  });
  assert.match(md, /^v0\.0\.1\.\.\.v0\.1\.0$/m);
  assert.doesNotMatch(md, /\]\(/);
});

test('GitHub 仓库 URL 生成完整 compare 链接', () => {
  const md = renderSection('1.1.0', [], {
    types,
    date: '2026-11-01',
    repoUrl: 'https://github.com/owner/project',
    previousTag: 'v1.0.0',
  });
  assert.match(
    md,
    /^## \[1\.1\.0\]\(https:\/\/github\.com\/owner\/project\/compare\/v1\.0\.0\.\.\.v1\.1\.0\)/,
  );
});

test('同 scope 条目也按 subject 全序，逆序输入生成相同内容', () => {
  const commits = [
    { type: 'fix', scope: 'db', subject: '乙' },
    { type: 'fix', scope: 'db', subject: '甲' },
  ];
  assert.equal(
    renderSection('1.1.0', commits, { types, date: '2026-11-01' }),
    renderSection('1.1.0', [...commits].reverse(), { types, date: '2026-11-01' }),
  );
});

test('空 CHANGELOG 使用 header，新版本置于已有历史之前', () => {
  const section = '## [1.1.0](compare) (2026-11-01)\n';
  assert.equal(
    mergeChangelog('', section, '# Changelog\n'),
    '# Changelog\n\n## [1.1.0](compare) (2026-11-01)\n',
  );
  assert.equal(
    mergeChangelog(
      '# Changelog\n\n## [1.0.0](compare) (2026-10-01)\n\nold\n',
      section,
      '# Changelog\n',
    ),
    '# Changelog\n\n## [1.1.0](compare) (2026-11-01)\n\n## [1.0.0](compare) (2026-10-01)\n\nold\n',
  );
});
