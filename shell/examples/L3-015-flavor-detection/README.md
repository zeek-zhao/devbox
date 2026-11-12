# L3-015-flavor-detection

## 考点
对应 KP-SH-L3-15：同一命令在 GNU/busybox 口味下行为不同，先探测口味再断言对应写法，脚本才可移植。

## 易错点
假定 GNU 写法到处可用，跑在 busybox 容器里 sed -i、date -d 直接报错；探测失败要显式报 unknown 而不是硬闯。

## 延伸
把探测封装成 lib/flavor.sh，CI 矩阵在两种口味的镜像里各跑一遍同一套用例。

## 复现
TAG=latest scripts/run-example.sh shell L3-015-flavor-detection
