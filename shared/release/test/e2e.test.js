// 端到端：在**临时 git 仓库**里跑完整流程。
// ------------------------------------------------------------------
// 纪律：只用临时仓库，绝不碰本仓库，绝不 push。
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const cli = fileURLToPath(new URL('../src/cli.js', import.meta.url));

function makeRepo(initialMessage = 'feat: 初始化') {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'zr-e2e-'));
  const run = (args) => execFileSync('git', args, { cwd: dir, encoding: 'utf8' });
  run(['init', '-q', '-b', 'work']);
  run(['config', 'user.email', 'test@example.com']);
  run(['config', 'user.name', 'test']);
  fs.writeFileSync(path.join(dir, 'VERSION'), '1.0.0\n');
  fs.writeFileSync(path.join(dir, 'package.json'), '{\n  "name": "t",\n  "version": "1.0.0"\n}\n');
  run(['add', '.']);
  run(['commit', '-q', '-m', initialMessage]);
  return { dir, run };
}

function release(repo, args = []) {
  return spawnSync(process.execPath, [cli, '--cwd', repo.dir, '--date', '2026-11-01', ...args], {
    cwd: repo.dir,
    encoding: 'utf8',
    env: { ...process.env, RELEASE_DATE: '2026-11-01' },
  });
}

test('dry-run 不改任何文件', () => {
  const repo = makeRepo();
  try {
    const beforeVersion = fs.readFileSync(path.join(repo.dir, 'VERSION'));
    const beforePackage = fs.readFileSync(path.join(repo.dir, 'package.json'));
    const result = release(repo);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /1\.1\.0/);
    assert.deepEqual(fs.readFileSync(path.join(repo.dir, 'VERSION')), beforeVersion);
    assert.deepEqual(fs.readFileSync(path.join(repo.dir, 'package.json')), beforePackage);
    assert.equal(fs.existsSync(path.join(repo.dir, 'CHANGELOG.md')), false);
    assert.equal(repo.run(['tag', '--list']).trim(), '');
    assert.equal(repo.run(['status', '--porcelain']).trim(), '');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('--write 之后版本号、CHANGELOG、tag 都到位', () => {
  const repo = makeRepo();
  const remote = path.join(path.dirname(repo.dir), `${path.basename(repo.dir)}-remote.git`);
  try {
    repo.run(['init', '--bare', '-q', remote]);
    repo.run(['remote', 'add', 'origin', remote]);
    const result = release(repo, ['--write']);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(path.join(repo.dir, 'VERSION'), 'utf8'), '1.1.0\n');
    assert.equal(JSON.parse(fs.readFileSync(path.join(repo.dir, 'package.json'), 'utf8')).version, '1.1.0');
    const changelog = fs.readFileSync(path.join(repo.dir, 'CHANGELOG.md'), 'utf8');
    assert.match(changelog, /## \[1\.1\.0\]/);
    assert.match(changelog, /初始化/);
    assert.equal(repo.run(['tag', '--list']).trim(), 'v1.1.0');
    assert.match(repo.run(['log', '-1', '--pretty=%s']), /chore\(release\): 1\.1\.0/);
    assert.equal(repo.run(['status', '--porcelain']).trim(), '');
    assert.equal(repo.run(['--git-dir', remote, 'for-each-ref', '--format=%(refname)']).trim(), '');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
    fs.rmSync(remote, { recursive: true, force: true });
  }
});

test('工作树脏时拒绝执行（退出码 2）', () => {
  const repo = makeRepo();
  try {
    fs.writeFileSync(path.join(repo.dir, 'untracked.txt'), 'dirty');
    const result = release(repo);
    assert.equal(result.status, 2);
    assert.match(result.stderr, /请先提交或 stash/);
    assert.equal(fs.readFileSync(path.join(repo.dir, 'VERSION'), 'utf8'), '1.0.0\n');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('受保护分支上拒绝执行，--allow-branch 后放行', () => {
  const repo = makeRepo();
  try {
    repo.run(['branch', '-m', 'main']);
    const denied = release(repo);
    assert.equal(denied.status, 2);
    assert.match(denied.stderr, /--allow-branch main/);
    const allowed = release(repo, ['--allow-branch', 'main']);
    assert.equal(allowed.status, 0, allowed.stderr);
    assert.match(allowed.stdout, /预览模式/);
    assert.equal(fs.readFileSync(path.join(repo.dir, 'VERSION'), 'utf8'), '1.0.0\n');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('白名单外的文件一个字节都不改', () => {
  const repo = makeRepo();
  try {
    fs.mkdirSync(path.join(repo.dir, 'images'));
    fs.writeFileSync(path.join(repo.dir, 'images', 'versions.env'), 'GO_VERSION=1.27.3\n');
    repo.run(['add', '.']);
    repo.run(['commit', '-q', '-m', 'chore: add dependency versions']);
    const before = fs.readFileSync(path.join(repo.dir, 'images', 'versions.env'));
    const result = release(repo, ['--write']);
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(fs.readFileSync(path.join(repo.dir, 'images', 'versions.env')), before);
    assert.equal(fs.readFileSync(path.join(repo.dir, 'VERSION'), 'utf8'), '1.1.0\n');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('没有任何有效提交时不打 tag、不动版本', () => {
  const repo = makeRepo('initial setup');
  try {
    const result = release(repo, ['--write', '--release-as', 'patch']);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /没有可发布的提交/);
    assert.equal(fs.readFileSync(path.join(repo.dir, 'VERSION'), 'utf8'), '1.0.0\n');
    assert.equal(fs.existsSync(path.join(repo.dir, 'CHANGELOG.md')), false);
    assert.equal(repo.run(['tag', '--list']).trim(), '');
    assert.equal(repo.run(['log', '-1', '--pretty=%s']).trim(), 'initial setup');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});
