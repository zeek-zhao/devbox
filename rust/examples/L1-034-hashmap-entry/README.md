# L1-034-hashmap-entry

## 考点
对应 KP-RS-L1-34：HashMap entry 与 BTreeMap 有序访问。输出先按键排序，而 BTreeMap 的首键直接是 apple，证明 entry 可避免重复查找且两类映射迭代性质不同

## 易错点
用 `contains_key` 判断后再 `insert`，会对同一个键做两次查找，也容易把“键已存在”的更新分支漏掉。`entry(key).or_default()` 一次定位后就能取得可变计数；需要稳定排序输出时则应选 `BTreeMap`，不能依赖 `HashMap` 的迭代顺序。

## 延伸
项目的 `src/lib.rs` 在 `process_lines` 中用 `BTreeMap::entry` 累加词频，并在合并 worker 结果时再次用 `entry` 汇总。这样既避免重复查找，也让最终文本索引按键有序输出。

## 复现
TAG=latest scripts/run-example.sh rust L1-034-hashmap-entry
