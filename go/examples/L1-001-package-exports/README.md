# L1-001-package-exports

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-01：用两个本地包展示包声明与导出规则。
包外通过大写开头的 `Summary` 调用功能，且结果稳定，说明掌握导出 API 的边界。

## 易错点
小写标识符在包外不可见；把实现留在 `main` 包会妨碍复用。
按职责拆包并只导出必要 API，包内辅助函数保持小写。

## 延伸
把解析、索引和查询拆成独立包，并让调用方只依赖公开 API。
继续练习包级测试，验证公开行为而不依赖内部辅助函数。

## 复现
TAG=latest scripts/run-example.sh go L1-001-package-exports
