# L2-012-cargo-config-alias

## 考点
对应 KP-RS-L2-12：.cargo/config.toml alias 与 target-dir。自定义 cargo alias 完成离线检查，构建产物落入配置的 target 子目录

## 易错点
把 Cargo alias 当成 shell alias 配置，或在仓库外目录执行它，会导致 Cargo 找不到该项目的本地配置。`.cargo/config.toml` 按目录层级生效；`target-dir` 也会改变构建产物位置，脚本和清理逻辑必须与该路径一致。

## 延伸
项目根目录的 `rust/project/.cargo/config.toml` 定义 `check-local` 离线检查别名和 `target-dir = "target"`，测试 `cargo_alias_and_target_directory_are_declared` 也核对这两项。离线开发依赖固定的本地 Cargo 配置，避免检查时意外访问网络并统一产物目录。

## 复现
TAG=latest scripts/run-example.sh rust L2-012-cargo-config-alias
