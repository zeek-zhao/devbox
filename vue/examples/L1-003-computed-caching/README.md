# L1-003-computed-caching

## 考点

连续读取依赖未变化的 computed 三次，getter 只执行一次，说明 computed 惰性求值并缓存结果。

## 易错点

computed 不等同于每次读取都执行的普通方法；依赖变化后缓存才会失效。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-003-computed-caching
```
