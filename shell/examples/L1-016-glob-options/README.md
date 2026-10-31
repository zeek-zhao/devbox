# L1-016-glob-options

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-16：观察无匹配 glob 的默认行为，并显式启用 `nullglob` 与 `globstar`。
看到默认模式保留一个字面字段、`nullglob` 变为零项，且递归模式找到深层文件，说明掌握了选项差异。

## 易错点
默认无匹配的 glob 会原样保留，可能被误当成文件名。
仅在需要时启用 `nullglob`；使用递归 `**` 前启用 `globstar`。

## 延伸
将 `nullglob` 用于安全发现可选文件，并对零项结果做明确处理。
探索用 `globstar` 枚举目录树时如何限制目标后缀和扫描范围。

## 复现
TAG=latest scripts/run-example.sh shell L1-016-glob-options
