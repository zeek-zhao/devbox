# L1-019-computed-setter

## 考点

可写 computed 的 setter 接收赋值，并负责更新源 ref；读取仍由 getter 派生。

## 易错点

给只读 computed 赋值不会自动改动依赖。setter 必须明确写入源状态。

## 延伸

用 writable computed 把表单模型映射到 store，同时在 setter 中集中规范化输入。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-019-computed-setter
```
