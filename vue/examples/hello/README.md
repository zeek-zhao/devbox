<!-- coverage: pending -->

# hello —— Vue 3 冒烟用例

## 考点

证明镜像里的 Vue 三件套都能 `require` 到，并且 SSR 输出是**确定的**：

| 包 | 在用例里做什么 |
|---|---|
| `vue` | `createSSRApp` 建应用（CJS 构建自带模板编译器） |
| `@vue/compiler-sfc` | 只验证 `parse` 存在 —— 后续 L1 用例要用它编 `.vue` |
| `@vue/server-renderer` | `renderToString` 把组件渲染成 HTML 字符串 |

## 为什么不用 vite

vite 的产物文件名带内容 hash（`index-3f2a1b.js`），`expected.txt` 没法固定。
本镜像统一走 **SFC + SSR 渲染**：输入是源码，输出是确定的 HTML 字符串，
可以直接逐行精确比对 —— 和另外六门语言的用例契约完全一致。

## 为什么用 require 而不是 import

依赖包是 `npm install --global` 装到 `/usr/local/lib/node_modules` 的。
Node 默认的模块解析路径里**不包含**全局目录，所以镜像设了
`NODE_PATH=/usr/local/lib/node_modules`。

而 `NODE_PATH` **只对 CommonJS 生效，ESM 不认它**。所以用例统一用 `require`。
这不是风格偏好，是镜像布局决定的硬约束。

## 运行

```bash
TAG=latest scripts/run-example.sh vue hello
```

## 易错点

- `renderToString` 是异步的，但**不要**指望用 `await` 之外的方式拿结果；
  忘了处理 Promise 会得到「只打印了 compiler-sfc 那行」的残缺输出。
- 模板里 `{{ who }}` 的 `who` 来自 `data()` 的返回值。写成 `data: { who: ... }`
  会让多个实例共享同一个对象 —— 这是 Vue 2 时代最经典的坑，Vue 3 里仍然存在。
