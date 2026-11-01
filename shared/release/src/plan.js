import fs from 'node:fs';
import path from 'node:path';
import { nextVersion } from './bump.js';
import { mergeChangelog, renderSection } from './changelog.js';
import { readVersion } from './version-file.js';

export function buildPlan({
  config, commits, currentVersion, releaseAs, date, repoUrl = '', previousTag,
}) {
  const next = nextVersion(currentVersion, commits, { releaseAs });
  const files = config.versionFiles.map((file) => ({
    path: file.path,
    from: readVersion({ ...file, path: path.resolve(config.cwd ?? process.cwd(), file.path) }),
    to: next,
  }));
  const changelogPath = path.resolve(config.cwd ?? process.cwd(), config.changelogPath);
  const existing = fs.existsSync(changelogPath) ? fs.readFileSync(changelogPath, 'utf8') : '';
  const section = renderSection(next, commits, {
    types: config.types,
    date: date ?? config.date,
    repoUrl,
    previousTag,
    tagPrefix: config.tagPrefix ?? 'v',
  });
  const changelog = mergeChangelog(existing, section, config.changelogHeader);
  return {
    currentVersion,
    nextVersion: next,
    files,
    changelog,
    changelogPath: config.changelogPath,
    tag: `${config.tagPrefix ?? 'v'}${next}`,
  };
}

export function formatPlan(plan) {
  const lines = [
    `版本：${plan.currentVersion} → ${plan.nextVersion}`,
    '版本文件：',
    ...plan.files.map((file) => `  ${file.path}: ${file.from} → ${file.to}`),
    `CHANGELOG：${plan.changelogPath}`,
    `Tag：${plan.tag}`,
  ];
  return lines.join('\n');
}
