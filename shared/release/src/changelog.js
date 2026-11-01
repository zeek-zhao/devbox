// 渲染 markdown 分节。
// ------------------------------------------------------------------
// 输出要满足：
//   - 每个版本一个 `## [x.y.z](compare-url) (YYYY-MM-DD)` 标题
//   - 按 config.types 的 section 分组，hidden 的类型不出现
//   - breaking changes 单独一节，且排在最前
//   - 同一版本内条目按 scope 再按 subject 排序（保证**渲染确定**，两次跑输出一样）
//   - 保留已有 CHANGELOG 的历史内容，新版本插在最前
export function renderSection(version, commits, { types, date, repoUrl } = {}) {
  // TODO(REL-01)
  throw new Error('未实现');
}

export function mergeChangelog(existing, section, header) {
  // TODO(REL-01)
  throw new Error('未实现');
}
