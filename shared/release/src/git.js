import { execFileSync } from 'node:child_process';

export function git(args, cwd) {
  return execFileSync('git', args, { cwd, encoding: 'utf8' }).trimEnd();
}

export function isClean(cwd) {
  return git(['status', '--porcelain', '--untracked-files=normal'], cwd) === '';
}

export function currentBranch(cwd) {
  return git(['branch', '--show-current'], cwd);
}

export function lastTag(cwd, prefix = 'v') {
  try {
    return git(['describe', '--tags', '--abbrev=0', '--match', `${prefix}*`], cwd);
  } catch (error) {
    if (error.status === 128) return null;
    throw error;
  }
}

export function createTag(cwd, name, message) {
  git(['tag', '-a', name, '-m', message], cwd);
}

export function commitAll(cwd, message) {
  git(['add', '-A'], cwd);
  git(['commit', '-m', message], cwd);
}
