---
title: WALKTHROUGH · T-001-borrow-trait-conflict（借用检查与特征冲突排查）
track: rust
lab: T-001-borrow-trait-conflict
难度: P2          # P0–P5 刻度：环境齐全、双缺陷、需读懂两类编译期诊断（E0119/E0502）与四处门禁
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 类型②实验（复现命令见 §1）+ 素材 S-06（「二进制未被执行被误读为代码问题」分支）
verified_env: devbox-rust:latest（rustc 1.99.1 / cargo 1.99.1 / clippy 1.99.1 / rustfmt 1.10.0）
---

# WALKTHROUGH · T-001-borrow-trait-conflict

> 依据 [docs/72 排障演练规范](../../../../docs/72-排障演练规范.md) §4 编写；结构沿用 W1 样板
> [cpp/examples/T-001-asan-heap-overflow](../../../cpp/examples/T-001-asan-heap-overflow/WALKTHROUGH.md)。
> 与样板的三处差异：① 故障形态从「运行期内存错误」换成「编译期拒绝」——没有 valgrind/gdb
> 可跑，工具换成 rustc / cargo / clippy / rustfmt 四件套；② Rust 借用检查器是**编译期**把关，
> 修复后没有内存复查环节，验证维度改为「编译绿 + 行为对 + lint 绿 + 格式绿」四样；
> ③ 双缺陷的掩蔽结构不同：C 里是「崩溃掩盖第二个缺陷」，Rust 里是「coherence 检查先于
> 借用检查，E0119 掩蔽 E0502」——修掉一个，另一个才浮出。所有输出均为 2026-11-06 在
> devbox-rust 容器内真跑所得（无地址/PID 需归一化，rustc 诊断本身不含）。

## 1. 触发症状

在 devbox-rust 容器内直接编译（无任何其他工具）：

```bash
rustc --edition 2021 main.rs -o /tmp/buggy
```

真实输出（类型②实验，2026-11-06，rustc 1.99.1）：

```text
error[E0119]: conflicting implementations of trait `Describe` for type `String`
  --> main.rs:16:1
   |
10 | impl<T: std::fmt::Debug> Describe for T {
   | --------------------------------------- first implementation here
16 | impl Describe for String {
   | ^^^^^^^^^^^^^^^^^^^^^^^^ conflicting implementation for `String`
   |
error: aborting due to 1 previous error
For more information about this error, try `rustc --explain E0119`.
```

**症状一：报错行不是病因行。** 诊断指向 16 行 `impl Describe for String`，但这个 impl
本身规规矩矩——真正源头是 10 行的 blanket impl `impl<T: Debug> Describe for T`，
String 实现 Debug 所以落进覆盖范围。先去改 16 行只会越改越乱。

**症状二：一个 error ≠ 一个缺陷。** main 函数里 25–27 行的借用冲突（E0502）真实存在，
但此刻编译输出只字未提——coherence（特征一致性）检查在编译管线里先于借用检查，
E0119 一报就 `aborting`，借用检查根本没轮到跑。**诊断里只见一个 error ≠ 只有一个缺陷**。

**症状三：编译期拒绝，运行无从谈起。** 没有二进制可跑、没有崩溃栈可看——排障对象从
「运行期行为」变成「编译器给出的结构化诊断」，判读技能是读 span 标注与错误码。

## 2. 前 60 秒三条只读检查（成本从低到高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | 重跑 `rustc --edition 2021 main.rs 2>&1 \| tail -3` 并看错误码 | `error[E0119]` + `rustc --explain E0119` 尾行 | **没有 error 行且退出 0** → 诊断可能来自别的源码/缓存；先确认编译对象就是这份 main.rs（素材 S-06：先排除环境，再谈代码） |
| 2 | `rustc --version; cargo --version; cargo clippy --version; rustfmt --version` | 四个版本号（1.99.1 / 1.99.1 / 1.99.1 / 1.10.0） | `command not found` 或版本形态大变 → 是环境/镜像问题（工具未装或工具链漂移），不是代码问题；停，交维护者 |
| 3 | `rustc --explain E0119 2>&1 \| head -20` | 官方长解释：什么是 coherence、overlap 规则、为什么被拒 | explain 报未知错误码 → rustc 版本漂移，停 |

三条都只读：不改代码、不改构建、不装东西。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q1 rustc/cargo 的报错里错误码是什么？
├─ E0119（conflicting implementations）
│     → 读三段 span：冲突发生地（^^^ 行）/ first implementation here（第一个 impl）/
│       --explain 深入口；判断哪边该收窄：被覆盖类型 Debug/Clone 等自动落入 blanket 时，
│       收窄 blanket（换具体类型），不要删具体 impl（会变 E0599）
│     → 修完再编译 → Q2
├─ E0502（cannot borrow ... as mutable because it is also borrowed as immutable）
│     → 读三段 span：冲突访问（主错误 ^^^ 行）/ *X* borrow occurs here（借用诞生地）/
│       *X* borrow later used here（存活区间另一端）；两条修法：挪走冲突访问 或
│       借改拷（仅当类型 Copy，如 i32）→ 修完再编译 → Q2
├─ E0599（no method ... found）
│     → 某类型的 trait 方法没了：多半是刚才删/改 impl 删过头；回 Q1 恢复正确实现
├─ 其他 E 码（E0382 move / E0277 trait bound ... 等）
│     → 与本 lab 现场不符（改错了行或工具链漂移），rustc --explain <码> 看解释后
│       对号入座；仍对不上 → 停止并登记 UNVERIFIED 交维护者
└─ 没有 error、退出 0 → Q1' 诊断真的来自这份源码吗？（素材 S-06 分支）
    ├─ 不确定 → ls -l /tmp/buggy 确认产物存在、`rustc --edition 2021 main.rs` 重跑确认
    │     报错行号与本文件的 trait/借用位置对得上（16 / 25–27 行）；对不上 →
    │     跑的是别的文件/路径错/容器没挂载 → 修环境，不是修代码
    └─ 确认对得上 → 逐个修，每修一个立刻重编译看下一个错（§4 判读 Q3）

Q2 修掉当前错误后重编译，退出码是 0 吗？
├─ 非零 → 回 Q1（下一个错误浮出；本 lab 顺序：E0119 → E0502 → 编译过）
└─ 零 → 编译过了，但不算修好：Q3 行为与门禁

Q3 行为与门禁四样都绿了吗？
├─ 运行标记行（run: start / first=90 total=4 / 字符串: 你好）+ 退出码 0
│   + cargo clippy -D warnings 过 + rustfmt --check 过 → 修好，去 §6 对照
└─ 任一不绿 → 哪样不绿修哪样；clippy 报的是修复引入的（如冗余写法）→ 就地
      #[allow] + 注释或改写，不许全局放宽（rust/docs/工具指南.md §2.3）
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-rust 容器真跑）

### 4.1 rustc 直译缺陷版（run.sh step 1）：E0119 与掩蔽

```text
error[E0119]: conflicting implementations of trait `Describe` for type `String`
  --> main.rs:16:1
   |
10 | impl<T: std::fmt::Debug> Describe for T {
   | --------------------------------------- first implementation here
16 | impl Describe for String {
   | ^^^^^^^^^^^^^^^^^^^^^^^^ conflicting implementation for `String`
error: aborting due to 1 previous error
For more information about this error, try `rustc --explain E0119`.
```

- `error[E0119]`：错误码是检索单位——`rustc --explain E0119` 可展开官方长解释，
  搜索引擎/issue 里也按码检索；
- 三段 span：**冲突发生地**（16 行，`^^^` 被拒的具体 impl）+ **第一个实现**（10 行，
  blanket）——两行合读才知道「重叠」是谁和谁；只看主错误行会冤枉 16 行；
- `aborting due to 1 previous error`：**只报了一个错就停**——coherence 检查先于
  借用检查，E0502 未上场。这不是「报几个错」的可配置项，是编译阶段顺序；
- 判读结论：修的方向是收窄 10 行的 blanket（换 `impl Describe for i32`，恰好覆盖
  `scores[0].describe()`），而不是动 16 行。

### 4.2 cargo check（run.sh step 2）：构建系统视角，同源诊断

```text
error[E0119]: conflicting implementations of trait `Describe` for type `String`
  --> src/main.rs:16:1
   ...
error: could not compile `lab-check` (bin "lab-check") due to 1 previous error
```

- 错误码、行号与 rustc 直译完全一致：**cargo 只是壳，诊断本体来自 rustc**，
  两条路径互证（也说明报错与构建方式无关，问题在源码）；
- 多出来的 `could not compile 'lab-check' (bin "lab-check")`：cargo 的包级汇总，
  bin 名来自 Cargo.toml 的 `name`——排查真实工程时这是定位「哪个 crate 没编过」的入口。

### 4.3 修掉 E0119 后（run.sh step 3）：E0502 浮出与三段标注读法

```text
error[E0502]: cannot borrow `scores` as mutable because it is also borrowed as immutable
  --> step1.rs:26:5
   |
25 |     let first = &scores[0];
   |                  ------ immutable borrow occurs here
26 |     scores.push(88);
   |     ^^^^^^^^^^^^^^^ mutable borrow occurs here
27 |     println!("first={} total={}", first, scores.len());
   |                                   ----- immutable borrow later used here
error: aborting due to 1 previous error
For more information about this error, try `rustc --explain E0502`.
```

**编译器三段标注怎么读（本 lab 核心判读）**——按因果链读，不是只看第一行：

1. **第一段（主错误行）**：`error[E0502]` 标题 + 26 行 `^^^^^^^^^^^^^^^` 指向「这次
   撞墙的可变访问」——`scores.push(88)` 要可变借用整个 vec；
2. **第二段（occurs here）**：25 行 `------` 指向不可变借用 `&scores[0]` 的**诞生地**，
   即撞的对象是谁、何时出生；
3. **第三段（later used here）**：27 行 `-----` 指向 `first` 还在被使用——借用**为什么
   还活着**（存活区间的另一端）。

三段合起来 = 借用存活区间 [25 行诞生 → 27 行仍使用] 与 26 行的可变访问重叠。两条修法：
挪走 push（借用诞生前做完所有可变操作）或借改拷——`i32` 是 Copy，
`let first = scores[0];` 拿值不留借用，本 lab 取后者（保留原语句顺序与语义）。

- 掩蔽解除：E0119 消失、E0502 出现——**第二个缺陷一直在源码里**，只是第一轮没轮到
  它上场。「逐个修」不是逐个制造错误，是编译器按阶段分批报告；
- 与 C 样板的同构：C 里崩溃掩盖第二个缺陷（裸跑死在缺陷 2 之前），Rust 里 coherence
  错误掩蔽借用错——「报错时只看到一个」永远不等于「只有一个」。

### 4.4 修复版编译 + 运行（run.sh step 4）：健康对照

```text
run: start
first=90 total=4
90
字符串: 你好
rc=0
```

- 标记行 `run: start` 打印（素材 S-06：二进制真的被执行过）；
- `first=90 total=4`：借改拷后 push 正常生效（total=4 = 3+1），first 拿到的是拷贝值 90；
- `90`：`scores[0].describe()` 走收窄后的 `impl Describe for i32`（Debug 格式化）；
- `字符串: 你好`：`impl Describe for String`（16 行）原样保留并正常分发——
  证明修复没有牺牲 String 的实现。

### 4.5 clippy + rustfmt 门禁（run.sh step 5）

```text
cargo clippy --offline --all-targets --color never -- -D warnings   → 退出 0，无警告
rustfmt --check --edition 2021 fixed.rs                             → 退出 0，无输出
```

对齐 CI 门禁（rust/docs/工具指南.md §2.3）：`-D warnings` 把 lint 警告提级为错误，
修复不得引入新警告；`rustfmt --check` 与 `scripts/fmt.sh --lang rust` 的仓库口径一致。
注意 `--color never`：cargo 在非 tty 环境也可能吐 ANSI 色码（实测），会污染 grep 锚点，
脚本里显式关掉。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑：

> **预测**：按报错行删掉 16 行的 `impl Describe for String`，程序能编译过吗？
> （多数人预测：能——编译器只报了这一个错。）

**观察**（真实输出）：

```text
删掉 16 行后：error[E0599]: no method named `describe` found for struct `String`（String 失去实现）
再修掉 E0119（收窄 blanket）后：error[E0502]: cannot borrow `scores` as mutable ...（又冒出一个错）
```

**explain 落差**：编译器报错 ≠ 全部缺陷清单。E0119 报的是「重叠」而非「谁写错了」，
删掉被拒的 impl 会把无辜的实现一起弄丢（E0599）；对的做法是收窄覆盖面过大的那一边。
同时修掉 coherence 后又冒出 E0502——编译按阶段报告，一次绿 ≠ 一次修完。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | 16 行的 impl 写错了，改/删 16 行即可 | 动 16 行后编译通过 | 删 16 行 → E0599（String 失去 describe）；改签名 → 仍 E0119 | 排除：源头是 10 行 blanket 覆盖面过大 |
| H2 | 借用问题是 review 多虑——编译器没报 = 不存在 | 修掉 E0119 后直接编译通过 | E0502 立刻浮出（25–27 行三段标注） | 排除：coherence 先于 borrow check，一个 error ≠ 一个缺陷 |
| H3 | 加一个 `impl Describe for &str` 能绕开冲突 | 重叠消失 | 冲突在「blanket 覆盖 String」本身；stable Rust 无 specialization/负约束，加 impl 只会制造新重叠 | 排除：只能收窄 blanket |
| H4 | `let first = scores[0];` 是碰运气，任何类型都能这么改 | 任意类型借改拷都编译通过 | 这条修法依赖 `i32: Copy`（值语义）；对非 Copy 类型同样改法会变 move、改变语义 | 排除风险：成立但依赖 Copy 事实，换类型要重新评估 |
| H5 | cargo 报错与 rustc 报错是两回事，要分别排查 | 两者错误码/行号不同 | E0119、main.rs:16 完全一致，cargo 多一条包级汇总 | 排除：诊断同源，cargo 只是壳 |

## 6. 改动后验证

修复 = 两处：10 行 blanket 收窄为 `impl Describe for i32`；25 行借改拷
`let first = scores[0];`。在**副本**上做（别改 lab 自身的缺陷现场，否则断言全红，lab 就废了）：

```bash
cd rust/examples/T-001-borrow-trait-conflict
sed -e 's/impl<T: std::fmt::Debug> Describe for T {/impl Describe for i32 {/' \
    -e 's/let first = &scores\[0\];/let first = scores[0];/' main.rs > /tmp/fixed.rs
rustc --edition 2021 /tmp/fixed.rs -o /tmp/fixed && /tmp/fixed; echo "rc=$?"
```

健康对照（2026-11-06 修复版真跑）：

```text
run: start
first=90 total=4
90
字符串: 你好
rc=0
```

对照 §1 的异常输出：E0119/E0502 全消、退出码 0。再过 lint 与格式门禁（真实输出）：

```text
$ cargo clippy --offline --all-targets --color never -- -D warnings   （退出 0，无警告）
$ rustfmt --check --edition 2021 /tmp/fixed.rs                        （退出 0，无输出）
```

四样齐了才算修好：编译绿（错误码全消）、行为对（标记行 + 数值对 + 特征分发对）、
lint 绿（clippy -D warnings）、格式绿（rustfmt --check）。修复版无需 valgrind/gdb——
借用检查在编译期把关内存安全，这是 Rust lab 与 C lab 验证流程的本质分工。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `rustc` / `cargo` / `clippy` / `rustfmt` 任一 `command not found`（镜像缺工具，环境问题）；
2. 同一验证命令**连续两次失败**（含 assert.sh 连红两次）；
3. 错误码形态与本 lab 现场不符（如 E0119 不再掩蔽 E0502、三段标注结构变化），提示
   rustc 版本漂移——掩蔽结构与标注文案是本 lab 判读的锚点；
4. `rustc --explain` 报未知错误码；
5. 需要修改 `rust/examples/T-001-borrow-trait-conflict/` 目录之外的文件才能继续；
6. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，devbox-rust:latest 容器（rustc 1.99.1 / cargo 1.99.1 /
clippy 1.99.1 / rustfmt 1.10.0，Docker on Linux）。`run.sh` 连跑 2 次、`assert.sh`
连跑 2 次，结论均一致（RUN-PASS 5/5、ASSERT-PASS）。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| 删除 16 行 impl 后的 E0599 现象（§5.1 POE 的观察段） | UNVERIFIED | 教学推演在设计实验中验证过一次，未作为正式 run.sh 判据复跑 | 下一位维护者跑变体：`grep -v 'impl Describe for String' main.rs > /tmp/h1.rs && rustc --edition 2021 /tmp/h1.rs` |
| 非 Copy 类型（如 String）借改拷不成立的对照实验（H4） | UNVERIFIED | 本 lab 现场只有 i32（Copy）；对照实验需另一份源码 | 做变体 lab（非 Copy 借用冲突单独成题）时补 |
| rust-gdb 在修复版上的断点调试 | UNVERIFIED | 本 lab 全部故障都在编译期，无运行期现场可调 | 出运行期 Rust lab 时补 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **类型②实验**：§1/§4 全部现象均为 2026-11-06 在 devbox-rust 容器内真跑所得，
  复现命令即 §1 与 `repro.sh`；输出无地址/PID（rustc 诊断本身不含），无内网信息。
- **来源：S-06**（docs/24-G3素材池.md）：「镜像探测失败被误读为代码问题」的 lab 化——
  §2 检查 1、§3 的 Q1' 分支（先证诊断来自这份源码：行号与本文件的 trait/借用位置对得上）
  都是该素材的应用。
