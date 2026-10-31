# L1-009-dispatch-overloads


## 考点
对应 KP-JV-L1-09：重写根据运行时对象派发，重载根据编译期参数类型选择。
父类引用调用到子类固定标签，且 `String` 与 `Object` 静态类型选中不同重载，即掌握此 KP。

## 易错点
预期重写会变成重载，因为参数签名不同。
使用 `@Override` 让编译器检查签名，并用固定标签验证实际选中的方法。

## 延伸
为存储实现定义稳定的父类接口，并比较重载 API 与运行时多态的职责。
通过改变变量的声明类型观察重载选择，而不改变实际对象。

## 复现
TAG=latest scripts/run-example.sh java L1-009-dispatch-overloads
