# SOLUTION · T-001-props-reactivity-env（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-vue 容器真跑（bundle hash 已归一化为 index-HASH.js）。

## 1. 先趟环境坑，再谈代码

devbox-vue 镜像只有 node/npm 与全局 vue，**没有 vite**：依赖必须走内嵌 app/ 工程的
`npm install`（产物落临时目录，不入库）。install 失败 = 环境问题（S-06 纪律），不能
顺手改代码。然后确认标记行 `PROPS-REPRO start` 打印了 → 脚本真的被执行过 → 可以谈代码。

## 2. 「文本不更新」：组件重渲染了吗，读的是哪份值

```text
update renders Bug=2 Good=2 text buggy=1 good=2
REACTIVITY-LOST: Bug re-rendered 2x but its text froze at 1 while live props.count = 2 (Good=2)
```

`Bug=2` 说明组件**重渲染了**——更新链路（props 传递 → 子组件 patch → 渲染函数执行）
完好。文本却冻在 1：`props-repro.mjs` 里 Bug 的 setup 做了
`const { count } = props`，解构那一刻对响应式代理做了一次属性读取，拿到原始值快照；
渲染闭包此后反复读的是这个 const，与代理无关。effect 隔离复证：

```text
EFFECT proxy-read=2 destructured-read=1
EFFECT-CONFIRMED: proxy read is tracked, destructured snapshot is not
```

依赖收集只认「经代理的读取」——解构出来的原始值从收集范围内消失。**改传参方式修不了
它**（Good 同样收值拷贝却正常，H2 否决），唯一修复：渲染时直读 `props.count`。
修复副本真跑：`update renders Bug=2 Good=2 text buggy=2 good=2` + `REACTIVITY-OK`，
退出码 0。

predict–observe–explain：预测「props 传了就都显示 2」→ 观察 `text buggy=1 good=2` →
解释：「props 传了」与「组件读到了」是两回事，解构绕开了依赖收集。

## 3. 产物里的 void 0 对回哪两行，为什么构建日志看不到

`src/main.js` 的两行消费点（VITE_API_URL / VITE_BUILD_TAG 在任何 .env* 里都没声明）：

```js
export const API_URL = import.meta.env.VITE_API_URL;
export const BUILD_TAG = import.meta.env.VITE_BUILD_TAG;
```

vite build 把未声明的 `import.meta.env.X` 静态替换为 `undefined`，压缩成 `void 0`：

```text
ENV-VOID0-COUNT=2 (undeclared env, bundle: index-HASH.js)
  | (e.href,t)}})();const s=void 0,c=void 0;co
```

构建日志看不到，是因为「未声明 = 合法的 undefined」是静态内联的默认行为、不是错误
（H3 否决「盯着日志就行」）；运行时也不报错，只是安静拿到 undefined。修复 =
声明进 `.env.production` 后 rebuild，验证凭产物证据：
`ENV-VOID0-AFTER=0` + `ENV-INLINED: API_URL=https://api.example.dev`。
判据钉在产物 grep，不钉在「构建没报错」（S-07：构建全绿 ≠ 配置在场）。

## 4. 被否决的假设（详见上层 WALKTHROUGH §5.2）

H1 响应式没触发更新 → 渲染计数 Bug=2 否决；H2 改传对象能修 → Good 对照否决；
H3 看构建日志能发现 → 零告警 + 产物 grep 才命中，否决；H4 define 与 .env 等价 →
都成立但 lab 判据统一钉产物 grep。
