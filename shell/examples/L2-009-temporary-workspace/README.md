# L2-009-temporary-workspace

<!-- coverage: pending -->

## 考点
对应 KP-SH-L2-09：临时工作区必须隔离创建并随脚本退出清理。
两个并发脚本记录到不同的 `mktemp -d` 目录，退出后目录都不存在，说明生命周期受控。

## 易错点
固定临时目录名会发生覆盖和竞态；不同运行可能同时改写同一路径。
用 `mktemp -d` 创建专属目录并注册 `EXIT` 清理，避免共享工作区和残留。

## 延伸
在部署工作区中集中放置临时配置、下载内容和测试夹具，并确保每个退出路径都清理。
为需要保留的诊断产物设计显式开关，默认仍执行清理。

## 复现
TAG=latest scripts/run-example.sh shell L2-009-temporary-workspace
