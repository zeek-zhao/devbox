// 端到端：在**临时 git 仓库**里跑完整流程。
// ------------------------------------------------------------------
// 纪律：只用临时仓库，绝不碰本仓库，绝不 push。
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

function makeRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'zr-e2e-'));
  const run = (args) => execFileSync('git', args, { cwd: dir, encoding: 'utf8' });
  run(['init', '-q', '-b', 'work']);
  run(['config', 'user.email', 'test@example.com']);
  run(['config', 'user.name', 'test']);
  fs.writeFileSync(path.join(dir, 'VERSION'), '1.0.0\n');
  fs.writeFileSync(path.join(dir, 'package.json'), '{\n  "name": "t",\n  "version": "1.0.0"\n}\n');
  run(['add', '.']);
  run(['commit', '-q', '-m', 'feat: 初始化']);
  return { dir, run };
}

test('dry-run 不改任何文件', () => {
  // TODO(REL-01)
});

test('--write 之后版本号、CHANGELOG、tag 都到位', () => {
  // TODO(REL-01)
});

test('工作树脏时拒绝执行（退出码 2）', () => {
  // TODO(REL-01)
});

test('受保护分支上拒绝执行，--allow-branch 后放行', () => {
  // TODO(REL-01)
});

test('白名单外的文件一个字节都不改', () => {
  // TODO(REL-01)
});

test('没有任何有效提交时不打 tag、不动版本', () => {
  // TODO(REL-01)
});
