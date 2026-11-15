// 根目录发版配置：覆盖默认的 versionFiles（根目录无 package.json，只以 VERSION 为版本真本）。
// 其余字段（tagPrefix / changelogPath / changelogHeader / types / protectedBranches）继承 shared/release 默认。
export default {
  versionFiles: [{ path: 'VERSION', kind: 'plain' }],
};
