---
title: WALKTHROUGH · T-001-props-reactivity-env（Vue 解构 props 丢响应性与生产环境变量内联）
track: vue
lab: T-001-props-reactivity-env
难度: P2          # P0–P5 刻度：需跨 Vue 运行时挂载观测 / reactivity effect 隔离 / vite 产物静态分析三类工具交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 类型②实验（复现命令见 §1）+ 素材 S-07（CI 全绿 ≠ 教学质量达标 → 构建成功 ≠ 配置在场）+ 素材 S-06（执行标记行纪律）
verified_env: ghcr.io/zeek-zhao/devbox-vue:latest（node v22.11.0 / npm 10.9.0 / vue 3.5.45 / vite 5.4.21，linux/amd64）
---

# WALKTHROUGH · T-001-props-reactivity-env

> 依据 [docs/72 排障演练规范](../../../../docs/72-排障演练规范.md) §4 编写。所有输出均为
> 2026-11-06 在 devbox-vue 容器内真跑所得（bundle 内容 hash 已按规范归一化为
> `index-HASH.js`，无内网信息）。与样板 go/examples/T-001-goroutine-leak 的差异点：
> Vue 轨道没有 ASan/valgrind 这类独立检测器，本 lab 的「多工具」是三类观测手段——
> ① headless 挂载真跑（`createRenderer` + 空操作 nodeOps，走完整响应式→组件更新→调度
> flush 路径，无 DOM 依赖）；② `@vue/reactivity` effect 层隔离；③ `vite build`
> 产物静态 grep。另有一个 Vue 轨道特有环境约束：vue/vite 不在镜像里预装，由内嵌
> app/ 工程 `npm install`（§4.0）。

## 1. 触发症状

**症状一：props 明明更新了，界面文本不动。** 父组件把 `state.count` 从 1 改到 2，
两个子组件都收到了新 prop（都重渲染了），但其中一个显示的永远是旧值。headless 真跑：

```bash
cd vue/examples/T-001-props-reactivity-env/app && npm install && node src/props-repro.mjs; echo "rc=$?"
```

真实输出（类型②实验，2026-11-06）：

```text
PROPS-REPRO start (headless custom renderer, no DOM)
first  renders Bug=1 Good=1 text buggy=1 good=1
update renders Bug=2 Good=2 text buggy=1 good=2
REACTIVITY-LOST: Bug re-rendered 2x but its text froze at 1 while live props.count = 2 (Good=2)
rc=1
```

`Bug` 组件渲染了 2 次（更新路径是通的），渲染出的文本却冻在 1；对照组 `Good` 拿到 2。
真实事故的形态：script setup 里顺手 `const { xxx } = props` 解构，之后父组件数据流
一切正常、其他字段都在动，唯独这个字段「永远慢一拍/卡死在初值」——**不报错、无告警、
`vue-tsc`/ESLint 全绿**（来源：S-07 的 Vue 变体，见 §5.2 H3）。

**症状二：`vite build` 成功、零告警，但产物里配置是 `void 0`。** 代码消费
`import.meta.env.VITE_API_URL`，而 `.env*` 文件没有声明它：

```bash
cd vue/examples/T-001-props-reactivity-env/app && npx vite build
grep -o 'void 0' dist/assets/*.js | wc -l
```

真实输出（构建退出 0、无任何告警）：

```text
ENV-VOID0-COUNT=2 (undeclared env, bundle: index-HASH.js)
  | (e.href,t)}})();const s=void 0,c=void 0;co
```

未声明的 env 被静态替换为 `undefined`、压缩后内联成 `void 0`——**线上拿到的是
undefined 而不是「构建期就该拦下来的配置缺失」**。

## 2. 前 60 秒三条只读检查（成本从低到高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | `node -v && npm -v` | `v22.11.0` / `10.9.0` | `command not found` → 工具不在场，是镜像/环境问题，不是代码问题；停，交维护者 |
| 2 | `bash repro.sh 2>&1 \| head -1; echo $?` | 标记行 `PROPS-REPRO start` 打印（素材 S-06：先证明脚本真被执行过） | 无标记行就报错/无错 → npm install 或脚本没跑成，先修环境（§4.0） |
| 3 | `grep -o 'void 0' app/dist/assets/*.js \| wc -l` | `0`（配置都已声明内联） | `>=1` → 产物里躺着 undefined，配置缺失坐实 |

三条都只读：不改代码、不触发构建产物改动、不装新东西（npm install 落在临时目录）。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q0 重跑 repro，标记行 PROPS-REPRO start 打印了吗？
├─ 没打印 → 素材 S-06 分支：先确认脚本真的被执行过——
│     ls ${TMPDIR:-/tmp}/devbox-vue-T-001-props-reactivity-env/app/node_modules （安装成功？）
│     npm registry 不可达 / node 不在场 → 修环境，不是修代码；连续两次失败 → 停
└─ 打印了 → Q1 更新对照行 text buggy=? good=?（update renders ...）
    ├─ buggy=1 good=2 → 丢响应性坐实 → Q2 Bug 是怎么读 props 的？
    │   ├─ setup 里解构（const { x } = props）且渲染闭包读解构变量
    │   │     → 病灶坐实：快照 vs 代理 → 用 effect-isolate.mjs 复证（§4.2）→ §6 修复
    │   ├─ 渲染闭包直读 props.x → 与本 lab 现场不符（Good 的健康路径），
    │   │     说明数据流另有断点 → 登记 UNVERIFIED 交维护者
    │   └─ 连 renders 都没涨（Bug=1）→ 更新根本没传导到子组件：
    │         查父组件是否把同一响应式对象当 prop 反复传（对象引用不变则子组件
    │         不触发 patch）→ 与本 lab 现场不同，停，另立现场
    └─ buggy=2 good=2 → 未复现：隔几秒重跑一次
        ├─ 仍绿 → 复现不可达（Vue 行为漂移？）→ 连续两次 → 停，登记 UNVERIFIED
        └─ 变红 → 首次跑到了缓存/半成品目录 → 清 TMPDIR 重跑

（附加）产物级：grep -o 'void 0' dist/assets/*.js | wc -l
├─ >=1 → Q1' 逐个 void 0 对回 src 里的 import.meta.env.X：.env* 里真的没有 X？
│   ├─ 没有 → 未声明 env 坐实 → §6 修复对照 A（声明 + rebuild + 复 grep）
│   └─ 有声明却还是 void 0 → 检查变量前缀（vite 只内联 VITE_ 前缀暴露给客户端）→ 前缀错也是本缺陷变体
└─ =0 → vite 版本漂移（不再压缩成 void 0？）或变量已全部声明 → 停，登记 UNVERIFIED
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-vue 容器真跑）

### 4.0 环境先行：vue/vite 由内嵌工程 npm install，产物只落临时目录

devbox-vue 镜像预装 node/npm（v22.11.0 / 10.9.0）与全局 vue 3.5.44 + @vue/compiler-sfc，
**但不带 vite**。本 lab 的 repro.sh/run.sh 把内嵌 `app/`（package.json + lock）复制到
`${TMPDIR:-/tmp}/devbox-vue-T-001-props-reactivity-env/` 后 `npm install`（实测
vue@3.5.45 / vite@5.4.21，安装 4s 左右）。教学点与素材 S-06 同源：**先分清「环境没备齐」
与「代码有缺陷」**——npm install 失败是环境问题，不能顺手改代码「让它跑起来」。
node_modules 只存在于临时目录，永不入库；仓库侧只有四文件 + app/ 源码 + lock。

### 4.1 headless 挂载真跑（运行时观测：渲染计数 + 文本快照）

```text
first  renders Bug=1 Good=1 text buggy=1 good=1
update renders Bug=2 Good=2 text buggy=1 good=2
REACTIVITY-LOST: Bug re-rendered 2x but its text froze at 1 while live props.count = 2 (Good=2)
```

- `update renders Bug=2 Good=2`：两个组件的渲染函数**都被调用了两次**——更新路径完全
  通畅，不是「props 没传到」，也不是「没等到 nextTick」；
- `text buggy=1 good=2`：同一个 patch 周期，Good 的宿主元素文本变成 2，Bug 的宿主元素
  文本还是 1。差异只剩一处可解释：**Bug 的渲染闭包读的值和 Good 不是同一个东西**——
  Bug 在 setup 里 `const { count } = props`，解构那一刻对响应式代理做了一次属性读取，
  拿到的是当时的原始值 `1`；之后渲染闭包反复读的只是这个 const 快照，与代理再无关联；
- `REACTIVITY-LOST ...`：机器可判定的坐实行（buggy≠live），脚本以 rc=1 结束
  （docs/72 §2 纪律：复现成功 = 非零退出）。
- 实现说明：`createRenderer` + 空操作 nodeOps 挂载真实 Vue 应用——不引 jsdom、不 mock
  Vue 内部，走的就是生产路径（reactive 追踪 → 父组件渲染 effect → 子组件 patch →
  scheduler flush）。宿主只按标签名收集 div/span 两个元素供判读文本。

### 4.2 effect 隔离（把现象钉到响应式原语层）

```text
EFFECT proxy-read=2 destructured-read=1
EFFECT-CONFIRMED: proxy read is tracked, destructured snapshot is not
```

- 同一个 `reactive({count:1})`，两个 effect 分别读 `props.count` 与解构快照 `count`；
  `props.count = 2` 之后：代理读法被通知重跑（2），快照读法无人通知（1）；
- 这一步把「组件更新了吗」的疑惑切掉：**依赖收集发生在属性读取的那一刻**，解构就是
  一次属性读取；effect（组件渲染函数同理）追踪的是「经代理的读取」，解构出来的原始值
  从此与响应式系统无关。修复方向由此唯一确定：渲染时直读 `props.count`。

### 4.3 vite build 产物静态分析（构建成功 ≠ 配置在场）

```text
ENV-VOID0-COUNT=2 (undeclared env, bundle: index-HASH.js)
  | (e.href,t)}})();const s=void 0,c=void 0;co
```

- `const s=void 0,c=void 0`：`src/main.js` 里两个 `import.meta.env.VITE_*` 被静态
  替换为 `undefined`，压缩器把它改写成 `void 0`——产物里的字面指纹；
- vite build 本身退出 0、无任何告警（§1）：env 未声明在 Vite 的默认行为里是「合法的
  undefined」，**构建日志里永远看不到这个问题**，必须产物级 grep；
- 修复对照（§6 A）：声明进 `.env.production` 后 rebuild，`ENV-VOID0-AFTER=0` 且
  `ENV-INLINED: API_URL=https://api.example.dev`——字面量直接内联进产物，两 grep
  一红一绿即机器可判定的修复验证。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑：

> **预测**：父组件把 count 从 1 改到 2，两个子组件都收到新 prop，界面上两处文本
> 分别显示多少？（多数人预测：两处都显示 2——「props 传了，就会更新」。）

**观察**（真实输出）：`update renders Bug=2 Good=2 text buggy=1 good=2`。

**explain 落差**：「props 传了」与「组件读到了」是两回事。解构发生在 setup 执行的
那一刻，读一次、拿一个原始值；渲染闭包每次执行读的都是这个快照，Vue 的依赖收集
**无从得知**这行代码还关心 props.count。组件照样重渲染（Bug=2），只是渲染结果
永远不变——这正是该缺陷在真实项目里「不报错、难归因」的原因：所有响应式设施都在
正常工作，唯独读法绕开了它们。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | 响应式系统没触发组件更新（调度/nextTick 问题） | Bug 的渲染计数停留在 1，或加长等待后文本追上 | `renders Bug=2`：渲染函数实打实跑了两遍，输出仍是 1 | 排除：更新链路完好，是**读法**绕开了追踪（§4.2 effect 隔离复证） |
| H2 | 是「传值拷贝」的错——改成传整个 reactive 对象（`v-bind` 对象透传）就能修 | 换传对象后 Bug 文本跟上更新 | Good 接收的同样是值拷贝（`{ count: state.count }`），却显示 2；传参方式两组件完全相同 | 排除：问题不在传参而在读取；单向数据流按值传 prop 本身没有错 |
| H3 | env 缺失会在构建日志或运行时控制台报错，盯着日志就能发现 | vite build 打出 warning/error，或浏览器控制台告警 | `vite build` 退出 0、零告警；产物运行时只是拿到 undefined，安静使用 | 排除：这是静态内联行为，唯一可靠观测点是产物 grep（§4.3） |
| H4 | vite 换个配置（如 define 手动注入）与 .env 声明等价，任选其一即可 | 两种修法产物 grep 都归零 | `.env` 声明走「环境文件→构建时内联」链路，define 走「编译期常量」链路；教学现场选 .env 因其与 CI/多环境组合正交 | 修正：两种修法都成立，但 lab 把判据统一钉在产物 grep，避免「换个修法断言就红」的假失败 |

## 6. 改动后验证

修复 = 两处独立改动（在**副本/临时目录**上做，别动 lab 自身的缺陷现场，否则断言全红）：

**A. 生产环境变量**（run.sh step 5 已内置）：

```bash
printf 'VITE_API_URL=https://api.example.dev\nVITE_BUILD_TAG=lab-demo\n' > app/.env.production
npx vite build && grep -o 'void 0' app/dist/assets/*.js | wc -l   # -> 0
grep -o 'https://api.example.dev' app/dist/assets/*.js | head -1  # -> https://api.example.dev
```

真实输出：`ENV-VOID0-AFTER=0`、`ENV-INLINED: API_URL=https://api.example.dev`。
两个维度都绿 = 修好：void 0 归零（不再有未内联的 undefined）+ 声明值字面在场。

**B. 解构 props**（run.sh step 6 已内置）：唯一改动是渲染闭包直读代理——

```diff
-    const { count } = props; // 缺陷：解构 props
-      return h("div", String(count));
+      return h("div", String(props.count)); // 渲染时直读响应式代理
```

真实输出：`update renders Bug=2 Good=2 text buggy=2 good=2`、
`REACTIVITY-OK: both components read live props (fix-verified path)`，退出码 0。
注意：只删解构语句而不改渲染闭包（或只改渲染闭包却保留快照变量参与渲染）都不会转绿——
判据钉在「渲染出的文本跟上更新」，不是钉在「代码长得像修好了」。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `node`/`npm` 不在场，或 npm install 连续两次失败（镜像/registry 环境问题）；
2. 同一验证命令连续两次失败（含 assert.sh 连红两次）；
3. `REACTIVITY-LOST` 不再出现（Vue 版本行为漂移——reactive/组件 patch 语义变化）；
4. 产物里不再出现 `void 0`（压缩器行为漂移或 vite 主版本升级）；
5. 需要修改 `vue/examples/T-001-props-reactivity-env/` 目录之外的文件（含 examples/）才能继续；
6. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，ghcr.io/zeek-zhao/devbox-vue:latest（node v22.11.0 /
npm 10.9.0 / vue 3.5.45 / vite 5.4.21，linux/amd64）。`assert.sh` 连跑 2 次均
ASSERT-PASS、退出码 0，结论一致；repro.sh rc=1（证据坐实纪律）、run.sh RUN-PASS 6/6。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| 浏览器 DOM 真实挂载（jsdom/happy-dom 或真浏览器）下的同一现象 | UNVERIFIED | 本 lab 用 createRenderer headless 路径，宿主 DOM 层未实测 | 做浏览器形态变体 lab 时补 |
| script-setup + `<script setup>` 编译宏（defineProps 解构响应性）路径 | UNVERIFIED | 本 lab 用渲染函数组件（props 语义一致），SFC 编译宏的 Reactivity Transform 已废弃、未实测 | 维护者拍板是否引入编译层变体 |
| vite 主版本升级（v6/v7）后 void 0 指纹是否仍在 | UNVERIFIED | 本 lab 锁 vite ^5.4.21（lockfile 固定） | 升级镜像版本时复跑 |
| 离线环境（无 npm registry）下 lab 可用性 | UNVERIFIED | npm install 需网络；本验证环境可达 | CI labs job（W3）落地时以镜像内置缓存兜底 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **类型②实验**：§1/§4 全部现象均为 2026-11-06 在 devbox-vue 容器内真跑所得，
  复现命令即 §1 与 `repro.sh`；输出已按 docs/72 §2 归一化（bundle 内容 hash →
  `index-HASH.js`），不含内网信息。
- **来源：S-07**（docs/24-G3素材池.md）：「CI 全绿 ≠ 教学质量达标」的 Vue 变体——
  §1 症状二（vite build 退出 0、零告警，产物却内联 void 0）与 §5.2 H3 都是该素材
  的应用；props 症状一同样全程无告警、无报错。
- **来源：S-06**（docs/24-G3素材池.md）：「镜像探测失败被误读为代码问题」——§2 检查 2、
  §3 Q0 分支（标记行缺失 → 先证脚本真的被执行过）与 §4.0 的 npm install 环境判读
  都遵循该素材的纪律。
