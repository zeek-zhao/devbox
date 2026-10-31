# L2-009-offline-build


## 考点
对应 KP-RS-L2-09：Cargo 仅使用标准库并以 `--offline` 构建。
看到工程无网络仍构建成功并输出固定结果，说明没有引入需下载的 crate。

## 易错点
会新增需要下载的包导致隔离容器构建失败；检查 manifest 与锁文件，只保留工具链自带标准库。
`--offline` 应用于实际构建命令，而不能只在本机缓存齐全时验收。

## 延伸
可在空 Cargo 缓存的环境中重复执行离线构建。
比较依赖树与 manifest，持续确认课程用例未增加外部 crate。

## 复现
TAG=latest scripts/run-example.sh rust L2-009-offline-build
