# L2-003-executable-jar


## 考点
对应 KP-JV-L2-03：Manifest Main-Class 使 JAR 可执行，辅助类也必须随包分发。
看到 JAR 清单含入口与 helper，且 `java -jar` 独立输出固定结果，即掌握打包完整性。

## 易错点
打包后找不到辅助类，因为只放入口 class。
从完整编译输出根目录打包，再用 java -jar 独立验证，不依赖外部 classpath。

## 延伸
继续为分发包加入资源文件，并验证资源定位不依赖当前工作目录。
了解可执行 JAR 的 manifest 属性及多入口应用的启动约定。

## 复现
TAG=latest scripts/run-example.sh java L2-003-executable-jar
