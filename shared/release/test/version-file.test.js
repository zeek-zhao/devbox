import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { readVersion, writeVersion, assertWritable } from '../src/version-file.js';

function tmp(content) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'zr-'));
  const f = path.join(dir, 'f');
  fs.writeFileSync(f, content);
  return f;
}

test('json 顶层 version', () => {
  const f = tmp('{"name":"x","version":"1.2.3"}');
  assert.equal(readVersion({ path: f, kind: 'json', key: 'version' }), '1.2.3');
});

test('json 点号路径', () => {
  const f = tmp('{"project":{"version":"0.1.0"}}');
  assert.equal(readVersion({ path: f, kind: 'json', key: 'project.version' }), '0.1.0');
});

test('plain', () => {
  const f = tmp('1.2.3\n');
  assert.equal(readVersion({ path: f, kind: 'plain' }), '1.2.3');
});

test('写 json 只改 version，其它字段原样', () => {
  const f = tmp('{\n  "name": "x",\n  "version": "1.2.3"\n}\n');
  writeVersion({ path: f, kind: 'json', key: 'version' }, '1.3.0');
  const out = fs.readFileSync(f, 'utf8');
  assert.match(out, /"version": "1.3.0"/);
  assert.match(out, /"name": "x"/);
});

test('白名单外的文件拒绝写', () => {
  const f = tmp('GO_VERSION=1.27.3\n');
  assert.throws(() => assertWritable({ path: f }, { versionFiles: [{ path: 'VERSION', kind: 'plain' }] }));
});
