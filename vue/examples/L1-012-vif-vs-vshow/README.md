<!-- coverage: pending -->

# L1-012-vif-vs-vshow

## 考点

同一 false 条件下比较 `v-if` 和 `v-show` 的 SSR HTML：`v-if` 不输出节点，`v-show` 输出带隐藏样式的节点。

## 易错点

`v-show` 保留元素并切换 `display`；`v-if` 控制元素是否存在。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-012-vif-vs-vshow
```
