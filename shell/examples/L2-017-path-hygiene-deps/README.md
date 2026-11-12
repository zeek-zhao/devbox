# L2-017-path-hygiene-deps

## 考点
对应 KP-SH-L2-17：脚本入口先做依赖前置检查（PATH 卫生 + command -v 清点），缺依赖在干活前报全。

## 易错点
跑到一半才发现缺命令，现场状态已经改了一半；把全部依赖集中在入口清点，缺项一次性报完。

## 延伸
在部署入口扩展依赖检查：命令之外再加文件权限、磁盘余量等环境前置条件。

## 复现
TAG=latest scripts/run-example.sh shell L2-017-path-hygiene-deps
