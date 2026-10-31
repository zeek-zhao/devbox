# L2-002-compile-bytecode


## 考点
对应 KP-JV-L2-02：干净编译显式指定 Java 21 目标，并检查调用字节码和 class 版本。
每次清理临时输出后以警告视为错误编译，看到 helper 调用且 major version 为 65 即掌握可复现构建。

## 易错点
干净构建会失败或误跑旧代码，因为混用残留 class 与默认编译配置。
每次创建干净临时目录、显式列出源文件和目标；只输出 javap 的稳定检查结论。

## 延伸
把固定编译选项纳入项目验收脚本，并将字节码检查用于验证 API 调用边界。
对比不同 `--release` 目标的 class 版本及可用平台 API。

## 复现
TAG=latest scripts/run-example.sh java L2-002-compile-bytecode
