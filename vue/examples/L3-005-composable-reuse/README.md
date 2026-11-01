# L3-005-composable-reuse —— 两组件复用逻辑但隔离状态

## 考点

- useCounter 在函数内部创建 ref，每次调用返回独立状态。
- 两个独立组件的 setup 各调用一次组合式函数，SSR 输出不同计数。
- 再修改 B，打印两份状态，验证 A 不受影响。

## 为什么这么写

组合式函数复用的是创建状态的逻辑，而不是单例状态。两个组件源码分别
写入临时 counter-a.js/counter-b.js，由同一入口注入 useCounter；
没有为了复用而将 ref 提升到模块级。仓库目录仍仅包含三个契约文件。
SSR 不提供浏览器交互，直接调用组件持有的 increment 验证隔离。

## 易错点

- 模块级 `const count = ref(0)` 会让 B 首次就显示 A 的值。
- 只比较两份包装对象不够，必须比较 ref 身份并修改其中一份。
- h 回调里直接使用 ref 对象而非 value，不能得到期望数字。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-005-composable-reuse
```
