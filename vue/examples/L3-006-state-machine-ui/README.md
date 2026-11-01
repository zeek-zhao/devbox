<!-- coverage: pending -->

# L3-006-state-machine-ui —— 转移表驱动的 UI

## 考点

- 显式定义 idle → loading → done/error，并允许重试和重置。
- 打印真实转移表；每次合法转移后 SSR 展示当前状态。
- idle 上 resolve 非法，打印允许事件且保持原状态。

## 为什么这么写

一个表同时承担行为定义与可观察输出，避免一串 if 与文档维护两套状态规则。
冻结转移表避免运行时偷偷新增边；状态存在 ref 中供组件消费。
非法输入有明确拒绝原因，不静默返回失败。

## 易错点

- 只按事件查目标、不按当前状态查表，会允许 idle 直接进入 done。
- 对象继承属性不应被当作合法事件，所以查找使用 Object.hasOwn。
- 拒绝事件不能先改状态再打印错误。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-006-state-machine-ui
```
