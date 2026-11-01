// 默认配置。目标仓库可以在根目录放一份同名文件覆盖任意字段。
// ------------------------------------------------------------------
// ★ versionFiles 是**白名单**，工具只会动这里显式列出的文件。
//   绝对不要给它加「自动推断版本号字段」的能力 —— devbox 的 images/versions.env
//   里全是 GO_VERSION=1.27.3 这类**依赖版本**，被当成项目版本 bump 一次就全盘皆错。
//   白名单之外的文件，工具一个字节都不许写。
export default {
  // conventional commits 的类型 -> changelog 分节标题
  types: [
    { type: 'feat', section: '✨ Features | 新功能' },
    { type: 'fix', section: '🐛 Bug Fixes | Bug 修复' },
    { type: 'docs', section: '✏️ Documentation | 文档' },
    { type: 'style', section: '💄 Styles | 风格' },
    { type: 'refactor', section: '♻️ Code Refactoring | 代码重构' },
    { type: 'perf', section: '⚡ Performance Improvements | 性能优化' },
    { type: 'test', section: '✅ Tests | 测试' },
    { type: 'build', section: '📦 Build System | 打包构建' },
    { type: 'ci', section: '👷 Continuous Integration | CI 配置' },
    { type: 'chore', section: '🚀 Chore | 构建/工程依赖/工具', hidden: true },
    { type: 'revert', section: '⏪ Revert | 回退', hidden: true },
  ],

  // 版本号所在文件的白名单（kind: json | plain | toml）
  versionFiles: [
    { path: 'package.json', kind: 'json', key: 'version' },
    { path: 'VERSION', kind: 'plain' },
  ],

  tagPrefix: 'v',
  changelogPath: 'CHANGELOG.md',
  changelogHeader: '# Changelog\n\n本文件由 `npx @zeek/release` 生成，请勿手改。\n',

  // 这些分支上默认拒绝执行（要 --allow-branch 显式授权）
  protectedBranches: ['main', 'master'],

  // 提交 release 时用的信息模板
  releaseCommitMessage: 'chore(release): {version}',
};
