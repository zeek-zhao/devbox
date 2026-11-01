import { execFileSync } from 'node:child_process';

export function git(args, cwd) {
  return execFileSync('git', args, {
    cwd,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  }).trimEnd();
}

export function isClean(cwd) {
  return git(['status', '--porcelain', '--untracked-files=normal'], cwd) === '';
}

export function currentBranch(cwd) {
  return git(['branch', '--show-current'], cwd);
}

export function lastTag(cwd, prefix = 'v') {
  const pattern = `${prefix}*`;
  if (!git(['tag', '--list', pattern], cwd)) return null;
  return git(['describe', '--tags', '--abbrev=0', '--match', pattern], cwd);
}

export function repositoryUrl(cwd) {
  if (!git(['remote'], cwd).split('\n').includes('origin')) return '';
  const remote = git(['remote', 'get-url', 'origin'], cwd);
  const ssh = /^git@github\.com:(.+)$/i.exec(remote);
  const https = /^https:\/\/github\.com\/(.+)$/i.exec(remote);
  const repository = (ssh?.[1] ?? https?.[1])?.replace(/\/+$/, '').replace(/\.git$/, '');
  return repository ? `https://github.com/${repository}` : '';
}

export function createTag(cwd, name, message) {
  git(['tag', '-a', name, '-m', message], cwd);
}

export function commitAll(cwd, message) {
  git(['add', '-A'], cwd);
  git(['commit', '-m', message], cwd);
}
