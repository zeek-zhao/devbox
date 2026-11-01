# L2-015-cfg-feature-gate

## 考点
对应 KP-RS-L2-15：cfg feature 与 cfg_attr 条件编译。默认和 trace feature 构建走不同代码分支，cfg_attr 在 feature 时派生 Debug

## 易错点
把 `cfg!` 当成删除未启用分支的条件编译，会让两边代码都参与类型检查；需要某段代码只在特性启用时存在，应使用 `#[cfg]`。`cfg_attr` 只在条件满足时添加属性，没启用 feature 时不能假定相应派生或 API 仍可用。

## 延伸
`rust/project/Cargo.toml` 声明 `strict-args` 和 `trace-demo`，`src/lib.rs` 用 `cfg` 选择缺省路径行为，并以 `cfg_attr` 条件派生 `TraceMode` 的 `Debug`。这让同一 CLI 能按构建 feature 改变参数策略或诊断能力，而无需在运行时判断。

## 复现
TAG=latest scripts/run-example.sh rust L2-015-cfg-feature-gate
