<!-- coverage: pending -->

# L2-006-package-exports —— 用 exports 限制包的公开入口

## 考点

- 从包根路径和明确导出的子路径加载模块。
- 验证未列入 `exports` 的文件不能被包使用者访问。

## 为什么这么写

临时包通过 `exports` 显式开放根入口和 `./safe`，同时保留一个存在但未导出的文件；实际执行 `require` 证明限制由 Node 模块解析实施。

## 易错点

- 文件存在不代表 `exports` 规则允许访问。
- 只捕获 `ERR_PACKAGE_PATH_NOT_EXPORTED`；其他加载错误必须继续抛出。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-006-package-exports
```
