# L3-023-leak-audit

## 考点

作用域 stop 与手动 watcher stop 都应阻止后续副作用；运行计数可发现遗漏的清理路径。

## 易错点

组件或请求创建的 watcher 若脱离其生命周期，仍会持有闭包并继续响应状态变化。

## 延伸

把相关 watcher 放进 effectScope 可集中清理；无法归组时则需保存每个 stop 函数并逐一调用。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-023-leak-audit
```
