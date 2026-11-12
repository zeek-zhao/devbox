# L3-010-symlink-handling

## 考点
对应 KP-SH-L3-10：链接用 -L 判本身、-e 判可达、readlink -f 求真身；目标删除后链接悬空但不消失。

## 易错点
用 -f 判链接存在会把悬空链接误报为完好；部署回滚时悬空的 current 软链是典型事故源。

## 延伸
把链接状态机接入发布目录：releases/ 多版本 + current 软链切换与回滚。

## 复现
TAG=latest scripts/run-example.sh shell L3-010-symlink-handling
