# L3-006-jni-native


## 考点
对应 KP-JV-L3-06：用 javac -h 生成 JNI 头，并加载匹配的本地库。
由生成头编译的 libprobe.so 正常返回 `2+3=5`，缺失库子进程非零失败，说明链接与错误路径均有效。

## 易错点
Java 声明与 JNI 符号签名不匹配会链接失败；硬编码 JAVA_HOME 会让构建路径失效。
使用生成头、按 javac 推导 JDK include，并核对库名；本例不获取字符串或数组，错误不返回伪造的 0。

## 延伸
为本地词项处理增加字符串或数组参数，并按 JNI API 配对释放取得的资源。
比较同一接口的 Java 实现与 JNI 实现，并把本地库限制为可选后端。

## 复现
TAG=latest scripts/run-example.sh java L3-006-jni-native
