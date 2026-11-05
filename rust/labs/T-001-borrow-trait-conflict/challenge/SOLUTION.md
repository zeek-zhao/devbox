# SOLUTION · T-001-borrow-trait-conflict（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-rust 容器真跑（rustc 1.99.1，地址已归一化）。

## 1. 报错行（16）不是冲突源头

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

E0119 的三段 span：**冲突发生地**（16 行，`^^^` 指向被拒的具体 impl）+ **第一个实现**（10 行，
blanket impl `impl<T: Debug> Describe for T`）+ 尾部 `--explain` 深入口。String 实现 Debug，
所以 String 落进 blanket impl 的覆盖范围——两个 impl 重叠，coherence（特征一致性）检查拒绝。
**报错点（16 行）只是被拒的那个 impl，真正的源头是 10 行的 blanket**：删 16 行会让
`String::from("你好").describe()` 失去实现；改 10 行才是对症的。coherence 检查在编译管线里
先于借用检查，E0119 一报就 `aborting`——**此时借用错根本没轮到跑**，这就是「编译输出里
看不到借用问题」的原因（与 C lab 的「崩溃掩盖缺陷」同构）。

predict–observe–explain：预测「按报错行删掉 16 行的 impl 就能编译」→ 观察删掉后
`String::from("你好").describe()` 报 E0599（no method `describe`），且接着又冒出 E0502 →
解释：报错行 ≠ 病因行；修掉掩蔽者后，下一个缺陷才浮出。

## 2. 借用错现形与三段标注读法（修掉 E0119 后）

```text
error[E0502]: cannot borrow `scores` as mutable because it is also borrowed as immutable
  --> step1.rs:26:5
   |
25 |     let first = &scores[0];
   |                  ------ immutable borrow occurs here      ← 第二段：借用的诞生地
26 |     scores.push(88);
   |     ^^^^^^^^^^^^^^^ mutable borrow occurs here            ← 第一段：主错误，冲突的这次访问
27 |     println!("first={} total={}", first, scores.len());
   |                                   ----- immutable borrow later used here
                                                              ← 第三段：借用的存活区间另一端
error: aborting due to 1 previous error
For more information about this error, try `rustc --explain E0502`.
```

三段标注的读法是**按因果链读，不是只看第一行**：第一段告诉你「哪次访问撞了」，
第二段告诉你「跟谁撞」（借用在 25 行诞生），第三段告诉你「为什么借用电还活着」
（27 行还在用它）。三条合起来 = 借用存活区间 [25 行诞生 → 27 行仍使用] 与 26 行的
可变访问重叠。两条修法：① 挪走 push（在借用诞生前 push）；② 借改拷——`i32` 是 Copy，
`let first = scores[0];` 直接拿值，借用区间消失。本 lab 取 ②，因为它保留原语义。

## 3. 被否决的假设（自查：你至少写了两条吗）

- H1 16 行的 impl 写错了？→ 若为真，删/改 16 行应恢复编译；实际动 16 行要么继续 E0119
  要么 E0599（String 失去 describe）→ 否：源头是 10 行 blanket 覆盖面过大。
- H2 借用问题是 review 多虑（编译器没报 = 不存在）？→ 若为真，修掉 E0119 后应直接编译
  通过；实际 E0502 立刻浮出 → 否：coherence 先于 borrow check，一个 error ≠ 一个缺陷。
- H3 用 `impl Describe for &str` 之类加更多 impl 能绕开冲突？→ 若为真，重叠消失；实际
  冲突在「blanket 覆盖 String」这件事本身，加 impl 只会制造新的重叠（stable Rust 没有
  specialization/负约束）→ 否：只能收窄 blanket（改 `impl Describe for i32`）。
- H4 `let first = scores[0];` 是「碰运气的写法」？→ 若为真，非 Copy 类型也会编译通过；
  实际这条路依赖 `i32: Copy`（值语义拷贝，无借用残留），对 String 等非 Copy 类型同样
  改法会变 move 而改变语义 → 排除风险：改法成立但要说明依赖 Copy 的事实，
  换类型要重新评估。

## 4. 修复 diff 与验证

修复 = 两处：10 行 blanket 收窄为 `impl Describe for i32`（覆盖 `scores[0].describe()`，
不再吞掉 String）；25 行借改拷 `let first = scores[0];`。在**副本**上做（别改 lab 自身的
缺陷现场，否则断言全红，lab 就废了）：

```diff
-impl<T: std::fmt::Debug> Describe for T {
+impl Describe for i32 {
...
-    let first = &scores[0]; // 不可变借用在此诞生
+    let first = scores[0]; // i32 是 Copy：借改拷，借用区间消失
```

验证（2026-11-06 修复版真跑）：

```text
$ rustc --edition 2021 fixed.rs -o fixed && ./fixed; echo rc=$?
run: start
first=90 total=4
90
字符串: 你好
rc=0

$ cargo clippy --offline --all-targets --color never -- -D warnings
（0 警告，退出 0）

$ rustfmt --check --edition 2021 fixed.rs
（无输出，退出 0）
```

判据四个维度：编译绿（E0119/E0502 全消）、行为对（run: start / first=90 total=4 /
字符串: 你好）、lint 绿（clippy -D warnings）、格式绿（rustfmt --check）。
修复版无运行时问题需要复查——借用检查器把关的是编译期，这正是 Rust「编译过 ≈ 内存安全」
与 C 需要跑 ASan/valgrind 的分工差异。
