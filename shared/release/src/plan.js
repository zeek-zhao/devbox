// 把上面组合成「将要做的事」列表。dry-run 打印的就是它。
// ------------------------------------------------------------------
// plan 是纯数据：{ currentVersion, nextVersion, files: [{path, from, to}], changelog: string, tag: string }
// 好处是 dry-run 和 --write 走同一条计算路径 —— 预览里看到什么，写下去就是什么。
export function buildPlan({ config, commits, currentVersion, releaseAs }) {
  // TODO(REL-01)
  throw new Error('未实现');
}

export function formatPlan(plan) {
  // TODO(REL-01)：人类可读的多行输出
  throw new Error('未实现');
}
