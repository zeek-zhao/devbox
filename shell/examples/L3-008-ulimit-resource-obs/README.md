# L3-008-ulimit-resource-obs

## 考点
对应 KP-SH-L3-08：ulimit 给子进程设资源上限；-f 超限写入触发 SIGXFSZ（退出码 153），文件截断在限额处（bash 的 -f 单位是 1024 字节块）。

## 易错点
以为设置 ulimit 会报错提前失败，实际是先写满限额再杀进程；-f 的单位随实现而变（bash 按 1024 字节），消费退出码时要用 128+信号号 解释。

## 延伸
给部署脚本按角色配额：巡检进程限 CPU/文件大小，防止失控脚本拖垮宿主。

## 复现
TAG=latest scripts/run-example.sh shell L3-008-ulimit-resource-obs
