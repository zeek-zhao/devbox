import { execFileSync } from 'node:child_process';

export function parseCommit(subject, body = '') {
  if (/^Merge\b/i.test(subject) || /^Revert "/.test(subject)) {
    if (/^Revert "/.test(subject)) {
      return { type: 'revert', scope: null, subject, breaking: false, body };
    }
    return null;
  }
  const match = /^([a-zA-Z][\w-]*)(?:\(([^()\r\n]+)\))?(!)?:\s+(.+)$/.exec(subject);
  if (!match) return null;
  return {
    type: match[1].toLowerCase(),
    scope: match[2] ?? null,
    subject: match[4],
    breaking: Boolean(match[3]) || /(?:^|\n)BREAKING(?: CHANGE)?:\s*\S/i.test(body),
    body,
  };
}

export function readCommits({ cwd, from, to = 'HEAD' }) {
  const args = ['log', '--format=%s%x00%b%x1e'];
  args.push(from ? `${from}..${to}` : to);
  const output = execFileSync('git', args, { cwd, encoding: 'utf8' });
  const commits = [];
  let skippedCount = 0;
  for (const [index, raw] of output.split('\x1e').entries()) {
    const record = index ? raw.replace(/^\n/, '') : raw;
    if (!record) continue;
    const separator = record.indexOf('\0');
    if (separator < 0) continue;
    const subject = record.slice(0, separator);
    if (!subject) continue;
    const parsed = parseCommit(subject, record.slice(separator + 1));
    if (parsed) commits.push(parsed);
    else skippedCount += 1;
  }
  Object.defineProperty(commits, 'skippedCount', { value: skippedCount });
  return commits;
}
