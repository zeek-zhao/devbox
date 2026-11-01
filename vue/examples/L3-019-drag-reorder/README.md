# L3-019-drag-reorder

## 考点

拖放手势可映射为纯 `reorder(list, from, to)` 状态转移，再从新顺序生成 SSR 列表。

## 易错点

直接修改原数组会污染调用方状态；索引越界应有明确结果，不能产生空洞或静默错误。

## 延伸

真实浏览器只需负责把拖动目标转换为 from/to，排序规则仍可独立测试。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-019-drag-reorder
```
