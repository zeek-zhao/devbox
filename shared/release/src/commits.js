// 从 git log 解析 conventional commits。
// ------------------------------------------------------------------
// 要处理的真实情况（不是玩具解析器）：
//   - merge commit（`Merge branch ...`）跳过
//   - revert commit 识别成 revert 类型
//   - 破坏性变更：`feat!: xxx` 或 footer 里的 `BREAKING CHANGE:`
//   - 没有 type 前缀的提交（如 `fix typo`）跳过，但要计数并在摘要里报出来
//   - 中文 subject 要能正常解析
export function parseCommit(subject, body = '') {
  // TODO(REL-01)：返回 { type, scope, subject, breaking, body }
  throw new Error('未实现');
}

export function readCommits({ cwd, from, to = 'HEAD' }) {
  // TODO(REL-01)：调 git log，解析成结构
  throw new Error('未实现');
}
