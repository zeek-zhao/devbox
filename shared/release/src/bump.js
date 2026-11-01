const VERSION_RE = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/;

function parseVersion(version) {
  const match = VERSION_RE.exec(version);
  if (!match) throw new Error(`无效的 semver 版本号：${version}`);
  if (match[4]?.split('.').some((part) => /^\d+$/.test(part) && part.length > 1 && part[0] === '0')) {
    throw new Error(`无效的 semver 预发布版本号：${version}`);
  }
  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
    prerelease: match[4]?.split('.') ?? [],
    build: match[5],
  };
}

function formatVersion(parts) {
  return `${parts.major}.${parts.minor}.${parts.patch}${parts.prerelease.length ? `-${parts.prerelease.join('.')}` : ''}${parts.build ? `+${parts.build}` : ''}`;
}

export function nextVersion(current, commits, { releaseAs } = {}) {
  const parts = parseVersion(current);
  if (releaseAs && VERSION_RE.test(releaseAs)) {
    parseVersion(releaseAs);
    return releaseAs;
  }
  let level = releaseAs;
  if (level && !['major', 'minor', 'patch'].includes(level)) {
    throw new Error(`无效的 release-as：${level}`);
  }
  if (!level) {
    if (!commits.length) return current;
    const breaking = commits.some((commit) => commit.breaking);
    // During 0.x, compatibility is scoped to the minor line, so a breaking change bumps minor.
    level = breaking ? (parts.major === 0 ? 'minor' : 'major')
      : commits.some((commit) => commit.type === 'feat') ? 'minor' : 'patch';
  }
  if (level === 'major') {
    parts.major += 1;
    parts.minor = 0;
    parts.patch = 0;
  } else if (level === 'minor') {
    parts.minor += 1;
    parts.patch = 0;
  } else {
    parts.patch += 1;
  }
  parts.prerelease = [];
  parts.build = undefined;
  return formatVersion(parts);
}

export function compareVersions(a, b) {
  const left = parseVersion(a);
  const right = parseVersion(b);
  for (const key of ['major', 'minor', 'patch']) {
    if (left[key] !== right[key]) return left[key] < right[key] ? -1 : 1;
  }
  if (!left.prerelease.length || !right.prerelease.length) {
    return left.prerelease.length === right.prerelease.length ? 0 : left.prerelease.length ? -1 : 1;
  }
  const length = Math.max(left.prerelease.length, right.prerelease.length);
  for (let i = 0; i < length; i += 1) {
    if (left.prerelease[i] === undefined) return -1;
    if (right.prerelease[i] === undefined) return 1;
    const x = left.prerelease[i];
    const y = right.prerelease[i];
    if (x === y) continue;
    const xn = /^\d+$/.test(x);
    const yn = /^\d+$/.test(y);
    if (xn && yn) return Number(x) < Number(y) ? -1 : 1;
    if (xn !== yn) return xn ? -1 : 1;
    return x < y ? -1 : 1;
  }
  return 0;
}
