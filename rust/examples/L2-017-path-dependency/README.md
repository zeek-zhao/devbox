# L2-017-path-dependency

## 考点
对应 KP-RS-L2-17：path 依赖与 package 重命名。离线程序以依赖别名调用本地 package，且别名和包名不同

## 易错点
本地 crate 的 package 名和依赖别名不同，却仍在代码里用 package 原名导入，会导致 crate 名解析失败。`package` 指定实际包名、依赖键指定代码里的别名；`path` 则必须指向包含目标 manifest 的目录，不能只填源文件路径。

## 延伸
`rust/project/Cargo.toml` 通过 `path = "test-support"` 依赖本地包 `rust_project_test_support`，并将它重命名为代码使用的 `local_test_support`。测试中的 `path_dependency_can_be_renamed` 调用这个别名，方便离线构建时复用同仓库的测试辅助 crate。

## 复现
TAG=latest scripts/run-example.sh rust L2-017-path-dependency
