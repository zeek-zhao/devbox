# L2-014-dev-dependencies

## 考点
对应 KP-RS-L2-14：[dev-dependencies] 的测试专用可见性。测试目标能使用本地 dev-only crate，而普通可执行程序不依赖它

## 易错点
把只供测试使用的 crate 放进普通 `[dependencies]`，会让生产构建也承担这项依赖。测试辅助库应放在 `[dev-dependencies]`，这样测试目标可以使用它，而正常库和二进制目标不会因此引入测试工具。

## 延伸
`rust/project/Cargo.toml` 把本地 `rust_project_test_support` 放在 `[dev-dependencies]`，而 `src/lib.rs` 的测试用它验证测试标记。它只服务测试目标，生产 CLI 不需要携带这项辅助 crate。

## 复现
TAG=latest scripts/run-example.sh rust L2-014-dev-dependencies
