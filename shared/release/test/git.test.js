import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { lastTag, repositoryUrl } from '../src/git.js';

function makeRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'zr-git-'));
  const run = (args) => execFileSync('git', args, { cwd: dir, encoding: 'utf8' });
  run(['init', '-q']);
  run(['config', 'user.email', 'test@example.com']);
  run(['config', 'user.name', 'test']);
  fs.writeFileSync(path.join(dir, 'README.md'), 'test\n');
  run(['add', '.']);
  run(['commit', '-q', '-m', 'test']);
  return { dir, run };
}

test('没有 tag 时 lastTag 返回 null 且不输出 stderr', () => {
  const repo = makeRepo();
  const moduleUrl = pathToFileURL(fileURLToPath(new URL('../src/git.js', import.meta.url))).href;
  try {
    const result = spawnSync(
      process.execPath,
      [
        '--input-type=module',
        '-e',
        `import { lastTag } from ${JSON.stringify(moduleUrl)}; console.log(lastTag(process.cwd()));`,
      ],
      { cwd: repo.dir, encoding: 'utf8' },
    );
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stdout, 'null\n');
    assert.equal(result.stderr, '');
    assert.equal(lastTag(repo.dir), null);
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('有匹配 tag 时 lastTag 返回最新 tag', () => {
  const repo = makeRepo();
  try {
    repo.run(['tag', '-a', 'v1.2.3', '-m', 'release']);
    assert.equal(lastTag(repo.dir), 'v1.2.3');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('仅有不匹配前缀的 tag 时 lastTag 返回 null', () => {
  const repo = makeRepo();
  try {
    repo.run(['tag', 'other-1.0.0']);
    assert.equal(lastTag(repo.dir), null);
    assert.equal(lastTag(repo.dir, 'other-'), 'other-1.0.0');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('存在匹配 tag 但不可从 HEAD 到达时仍抛出 describe 错误', () => {
  const repo = makeRepo();
  try {
    repo.run(['tag', 'v1.0.0']);
    repo.run(['checkout', '-q', '--orphan', 'unrelated']);
    repo.run(['commit', '-q', '-m', 'unrelated history']);
    assert.throws(
      () => lastTag(repo.dir),
      (error) => {
        assert.equal(error.status, 128);
        assert.match(error.stderr.toString(), /cannot describe|can describe/i);
        return true;
      },
    );
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('git 不存在时 lastTag 不掩盖 ENOENT', () => {
  const repo = makeRepo();
  const moduleUrl = new URL('../src/git.js', import.meta.url).href;
  try {
    const result = spawnSync(
      process.execPath,
      [
        '--input-type=module',
        '-e',
        `import assert from 'node:assert/strict';
         import { lastTag } from ${JSON.stringify(moduleUrl)};
         assert.throws(() => lastTag(process.cwd()), { code: 'ENOENT' });`,
      ],
      { cwd: repo.dir, encoding: 'utf8', env: { ...process.env, PATH: repo.dir } },
    );
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stderr, '');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('lastTag 不掩盖非 git 仓库错误', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'zr-not-git-'));
  try {
    assert.throws(() => lastTag(dir), /not a git repository/i);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test('没有 origin remote 时 repositoryUrl 返回空字符串', () => {
  const repo = makeRepo();
  try {
    assert.equal(repositoryUrl(repo.dir), '');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('repositoryUrl 不掩盖非 git 仓库错误', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'zr-not-git-'));
  try {
    assert.throws(() => repositoryUrl(dir), /not a git repository/i);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test('repositoryUrl 将 SSH GitHub remote 转为 HTTPS URL', () => {
  const repo = makeRepo();
  try {
    repo.run(['remote', 'add', 'origin', 'git@github.com:owner/project.git']);
    assert.equal(repositoryUrl(repo.dir), 'https://github.com/owner/project');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});

test('repositoryUrl 保留 HTTPS GitHub remote 并移除 .git', () => {
  const repo = makeRepo();
  try {
    repo.run(['remote', 'add', 'origin', 'https://github.com/owner/project.git']);
    assert.equal(repositoryUrl(repo.dir), 'https://github.com/owner/project');
  } finally {
    fs.rmSync(repo.dir, { recursive: true, force: true });
  }
});
