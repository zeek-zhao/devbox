# L2-001-cargo-lib-bin


## 考点
对应 KP-RS-L2-01：同一 package 同时提供库目标与二进制目标。
看到二进制通过 crate 名调用库函数并打印结果，说明核心 API 可复用且入口负责编排。

## 易错点
把全部业务逻辑塞进二进制入口，会让其他目标无法直接复用。
将核心 API 放入 `src/lib.rs`，让 `src/main.rs` 只负责流程编排。

## 延伸
为库 API 增加单元测试，并让多个 CLI 入口共享该库。
将索引查询逻辑放进库，由命令行入口处理参数与输出。

## 复现
TAG=latest scripts/run-example.sh rust L2-001-cargo-lib-bin
