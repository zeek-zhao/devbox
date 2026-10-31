# L2-010-cargo-workspace

<!-- coverage: pending -->

## 考点
对应 KP-RS-L2-10：workspace 根清单列出两个成员并共享版本与 edition 设置。
看到根目录的 `cargo test --workspace --offline` 通过两个成员的测试，说明统一发现成员生效。

## 易错点
会只在成员目录运行测试而漏掉其他 crate；从 workspace 根目录执行统一命令并明确成员清单。
成员共享字段必须显式继承 workspace 设置，成员列表也应与实际 crate 保持一致。

## 延伸
将 CLI 与核心库分别演进，并在根目录运行整个 workspace 的测试。
继续集中管理 lint 与依赖版本策略，避免成员配置逐渐分叉。

## 复现
TAG=latest scripts/run-example.sh rust L2-010-cargo-workspace
