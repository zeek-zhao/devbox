coverage: exempt 项目待办列表按用户添加顺序以数组渲染，不使用对象键或 Map 作为视图数据源。

# L1-027-vfor-object-order

## 考点

整数样式对象键按 JavaScript 规则先排序，普通字符串键按插入顺序；Map 保留插入顺序。

## 易错点

VNode `key` 用于客户端 diff，不会作为 HTML 属性输出，不能从 SSR 标签上读取它。

## 延伸

依赖顺序的列表应使用数组或 Map，并为每个 vnode 提供稳定 key。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-027-vfor-object-order
```
