# L3-011-theme-tokens —— 注入不可变主题令牌

## 考点

- 父组件 provide 主题令牌，子组件仅通过 inject 消费。
- 同一个子组件 SSR 明暗两种主题，实际内联样式来自令牌。
- 冻结令牌并在子组件尝试写入，严格模式下确认 TypeError。

## 为什么这么写

Symbol 注入键避免字符串冲突，不通过 props 偷渡颜色。每个主题对象单独冻结；
令牌全是原始值，所以浅冻结足够。缺 provider 或未知主题明确抛错，
避免悄悄回退到默认主题掩盖接线问题。

## 易错点

- 只冻结 themes 外层，内部 light/dark 仍可被改坏。
- 非严格模式对冻结对象赋值可能静默失败，无法验证拒绝机制。
- setup 之外调用 provide 没有组件注入上下文。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-011-theme-tokens
```
