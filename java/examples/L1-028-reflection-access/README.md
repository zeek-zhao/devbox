# L1-028-reflection-access


## 考点
对应 KP-JV-L1-28：反射查找声明成员，并区分默认访问检查与自有类开放访问。
看到独立顶层类的私有方法先触发 IllegalAccessException，开放后调用成功，缺失方法报 NoSuchMethodException，即说明掌握。

## 易错点
同一 nest 的嵌套类可能本就能互访，导致私有访问负例失真；本例使用独立顶层类。
只对未命名模块中的自有类开放访问，不假设 setAccessible 能突破 JDK 模块封装。

## 延伸
为自有命令处理器检查反射入口，区分成员不存在、访问被拒和目标方法失败。
了解命名模块的开放配置，并避免把反射访问扩展到 JDK 内部实现。

## 复现
TAG=latest scripts/run-example.sh java L1-028-reflection-access
