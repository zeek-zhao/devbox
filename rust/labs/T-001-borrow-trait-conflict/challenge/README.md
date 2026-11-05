# T-001-borrow-trait-conflict · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障：`main.rs` 的程序「编译不过，报特征冲突」，他自己加了一个 trait 却越改报错越多。
你本地直跑（devbox-rust 镜像内）：

```bash
rustc --edition 2021 main.rs -o /tmp/buggy
```

输出只有一条错：

```text
error[E0119]: conflicting implementations of trait `Describe` for type `String`
  --> main.rs:16:1
...
error: aborting due to 1 previous error
```

按报错行（16 行）看 `impl Describe for String`，怎么读都觉得这个 impl 本身没毛病；
而且 review 时有人指出 main 函数里「引用和 push 混着用」的写法很可疑，
但编译输出里只字未提借用问题。

## 你的任务

1. 先排除「诊断不是来自这份源码/环境探测失败」（素材 S-06 的分支）；
2. 解释为什么报错行（16 行）不是冲突的真正源头，把两处 impl 都钉出来；
3. 解释为什么编译输出里看不到借用问题——它真的存在吗？用什么顺序修才能让它现形？
4. 读懂 E0502 的三段 span 标注（错误行 / occurs here / later used here），给出修复 diff
   与修复后的验证证据（编译 + 运行 + lint/格式门禁都要复查）。

## 可用工具清单（均在 devbox-rust 镜像内，宿主上没有）

- rustc（`--explain E0502` / `--explain E0119` 可展开错误长解释）
- cargo（check / clippy；构建系统视角，诊断本体与 rustc 同源）
- clippy（`cargo clippy --offline --all-targets -- -D warnings`，CI lint 门禁）
- rustfmt（`rustfmt --check --edition 2021`，CI 格式门禁）
- 同目录 `repro.sh` / `run.sh` / `assert.sh` 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设。
