# E-008-strong-guarantee

## 现象
同一容器两种 add 实现：`add_strong` 失败（注入 boom）后 size 与内容
与操作前**完全一致**（size=2，最后一项仍是 bob）；`add_weak` 的对照
场景里故障发生时状态已经改掉、无法回滚。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-008-strong-guarantee
```

## 期望输出
```text
before: size=2 first=ada
failed: storage full
after: size=2 last=bob
weak: add done, failure incoming
weak: size=1 (state already changed)
```

## 为什么
强保证 = 「失败时对象回到操作前的状态」。直接在原对象上逐步修改，
任何一步抛出都会留下半成品；而「staged 副本先做完所有可能抛的操作，
最后用不抛的 move 赋值提交」把故障面压缩到提交点之前——提交动作本身
不抛，就必然要么全成、要么原样。区别于 L1-024 的基本保证（只要求
不泄漏、状态有效）：强保证额外承诺状态可回滚，代价是失败路径多一份拷贝。
需要 O(1) 空间的场景退回基本保证，但要写明「失败后状态是 X」给调用方。

## 反例
边改状态边做可能抛的操作（push 之后做校验、校验失败抛出）——状态
进退两难；或者提供 rollback 函数手工回滚每个字段——新增字段时必然
漏掉一处；或者声称强保证却依赖「析构不抛」之外的抛出式提交（move
赋值用了会抛的拷贝版本）。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
