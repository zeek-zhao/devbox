import test from 'node:test';
import assert from 'node:assert/strict';
import { nextVersion, compareVersions } from '../src/bump.js';

test('fix -> patch', () => {
  assert.equal(nextVersion('1.2.3', [{ type: 'fix' }]), '1.2.4');
});

test('feat -> minor', () => {
  assert.equal(nextVersion('1.2.3', [{ type: 'feat' }]), '1.3.0');
});

test('breaking -> major', () => {
  assert.equal(nextVersion('1.2.3', [{ type: 'feat', breaking: true }]), '2.0.0');
});

test('0.x 下 breaking 按 minor 处理', () => {
  assert.equal(nextVersion('0.3.1', [{ type: 'feat', breaking: true }]), '0.4.0');
});

test('没有有效提交时版本不变', () => {
  assert.equal(nextVersion('1.2.3', []), '1.2.3');
});

test('release-as 覆盖推断', () => {
  assert.equal(nextVersion('1.2.3', [{ type: 'fix' }], { releaseAs: 'major' }), '2.0.0');
  assert.equal(nextVersion('1.2.3', [], { releaseAs: '2.5.0' }), '2.5.0');
});

test('预发布版本', () => {
  assert.equal(nextVersion('1.2.3', [{ type: 'fix' }], { releaseAs: 'patch' }), '1.2.4');
  assert.equal(nextVersion('1.2.3', [], { releaseAs: '1.2.4-rc.0' }), '1.2.4-rc.0');
});

test('compareVersions', () => {
  assert.equal(compareVersions('1.2.3', '1.2.4'), -1);
  assert.equal(compareVersions('1.2.3', '1.2.3'), 0);
  assert.equal(compareVersions('2.0.0', '1.9.9'), 1);
});
