coverage: exempt Todo 列表是扁平集合，没有父子层级数据；把待办强行嵌套成树会改变项目领域模型。

# L1-022-recursive-component

## 考点

自引用组件逐个渲染节点，并在 `children` 为空时停止递归。

## 易错点

缺少明确的终止条件会导致递归永远继续；树形遍历还应为子节点提供稳定 key。

## 延伸

目录树、评论回复和组织架构通常用递归组件表达层级数据。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-022-recursive-component
```
