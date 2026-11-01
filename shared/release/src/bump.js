// 由 commits 算下一个版本。
// ------------------------------------------------------------------
// 规则（与 semver 一致，不许自创）：
//   - 有 breaking -> major（0.x 时按 minor 处理，这是 semver 的惯例，要写进注释）
//   - 有 feat -> minor
//   - 其它 -> patch
//   - 没有任何有效提交 -> 不动版本，退出码 0 并提示「没有可发布的提交」
// 也要支持显式指定：major / minor / patch / 确切版本号（含预发布 1.2.3-rc.0）
export function nextVersion(current, commits, { releaseAs } = {}) {
  // TODO(REL-01)
  throw new Error('未实现');
}

export function compareVersions(a, b) {
  // TODO(REL-01)：semver 比较，返回 -1 | 0 | 1
  throw new Error('未实现');
}
