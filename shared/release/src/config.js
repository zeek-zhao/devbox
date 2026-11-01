// 读 release.config.js，校验并补默认值。
// ------------------------------------------------------------------
// 校验必须严格：
//   - versionFiles 每项要有 path 和 kind；kind 只能是 json | plain | toml
//   - types 每项要有 type 和 section
//   - protectedBranches 是字符串数组
// 校验失败要报出**具体哪一项**不对，不能只说「配置错误」。
export async function loadConfig(cwd) {
  // TODO(REL-01)：从 cwd 找 release.config.js，找不到就用本包默认值
  throw new Error('未实现');
}

export function validateConfig(cfg) {
  // TODO(REL-01)：见上
  throw new Error('未实现');
}
