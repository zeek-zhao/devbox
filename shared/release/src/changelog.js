function compareEntries(a, b) {
  const fieldsA = [a.scope ?? '', a.subject ?? '', a.type ?? '', a.body ?? ''];
  const fieldsB = [b.scope ?? '', b.subject ?? '', b.type ?? '', b.body ?? ''];
  for (let i = 0; i < fieldsA.length; i += 1) {
    if (fieldsA[i] !== fieldsB[i]) return fieldsA[i] < fieldsB[i] ? -1 : 1;
  }
  return 0;
}

function lineFor(commit) {
  const scope = commit.scope ? `**${commit.scope}**: ` : '';
  return `* ${scope}${commit.subject}`;
}

export function renderSection(version, commits, {
  types = [], date, repoUrl = '', previousTag, tagPrefix = 'v',
} = {}) {
  const releaseDate = date ?? process.env.RELEASE_DATE;
  if (!releaseDate) throw new Error('必须通过 --date 或 RELEASE_DATE 指定 CHANGELOG 日期');
  const normalizedRepo = repoUrl.replace(/\/+$/, '');
  const currentTag = `${tagPrefix}${version}`;
  const compareUrl = `${normalizedRepo ? `${normalizedRepo}/` : ''}compare/${previousTag ?? `${currentTag}^`}...${currentTag}`;
  const output = [`## [${version}](${compareUrl}) (${releaseDate})`];
  const breaking = commits.filter((commit) => commit.breaking).sort(compareEntries);
  if (breaking.length) {
    output.push('', '### ⚠️ Breaking Changes', ...breaking.map(lineFor));
  }
  const configured = types.map((item, index) => ({ ...item, index }))
    .filter((item) => !item.hidden)
    .sort((a, b) => a.index - b.index);
  const sections = new Map();
  for (const commit of commits) {
    const type = configured.find((item) => item.type === commit.type);
    if (!type) continue;
    if (!sections.has(type.index)) sections.set(type.index, { label: type.section, commits: [] });
    sections.get(type.index).commits.push(commit);
  }
  for (const index of [...sections.keys()].sort((a, b) => a - b)) {
    const section = sections.get(index);
    output.push('', `### ${section.label}`, ...section.commits.sort(compareEntries).map(lineFor));
  }
  return `${output.join('\n')}\n`;
}

export function mergeChangelog(existing, section, header) {
  const cleanSection = `${section.trimEnd()}\n`;
  if (!existing) {
    const prefix = header ?? '# Changelog\n';
    return `${prefix.replace(/\s*$/, '\n\n')}${cleanSection}`;
  }
  const firstVersion = /^## /m.exec(existing);
  if (firstVersion) {
    const before = existing.slice(0, firstVersion.index);
    const prefix = before.endsWith('\n\n') ? before : `${before.replace(/\n*$/, '')}\n\n`;
    return `${prefix}${cleanSection}\n${existing.slice(firstVersion.index)}`;
  }
  return `${existing.replace(/\s*$/, '\n\n')}${cleanSection}`;
}
