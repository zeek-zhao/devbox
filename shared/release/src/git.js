// tag / commit 封装。**不做任何 push，不发起网络请求。**
import { execFileSync } from 'node:child_process';

export function git(args, cwd) {
  // TODO(REL-01)：execFileSync('git', args, { cwd, encoding: 'utf8' })
  throw new Error('未实现');
}

export function isClean(cwd) {
  // TODO(REL-01)：工作树是否有未提交改动
  throw new Error('未实现');
}

export function currentBranch(cwd) {
  // TODO(REL-01)
  throw new Error('未实现');
}

export function lastTag(cwd, prefix) {
  // TODO(REL-01)：取最近的版本 tag，没有则返回 null
  throw new Error('未实现');
}

export function createTag(cwd, name, message) {
  // TODO(REL-01)：附注标签（annotated），不是轻量标签
  throw new Error('未实现');
}

export function commitAll(cwd, message) {
  // TODO(REL-01)
  throw new Error('未实现');
}
