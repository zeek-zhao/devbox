# L1-026-to-refs-props

## 考点

直接解构取得当前值快照；`toRefs` 为每个属性建立与原响应式对象同步的 ref。

## 易错点

解构不会自动保留 Proxy 属性访问，因此后续替换 props 字段不会更新普通局部变量。

## 延伸

组合式函数可以接收 `toRefs(props)` 后的属性，同时保留每个输入的响应式来源。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-026-to-refs-props
```
