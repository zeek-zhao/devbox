# L1-010-interface-methods


## 考点
对应 KP-JV-L1-10：实现类可继承或重写 default 方法，接口 static 方法通过接口名调用。
两个 default 冲突由显式重写消解，且接口静态方法可调用但不被实现类继承，即掌握此 KP。

## 易错点
双接口 default 冲突会阻止编译，因为没有唯一实现。
显式重写并按需使用 `接口名.super` 调用指定默认实现；静态方法经接口名访问。

## 延伸
为存储接口定义通用默认校验，并用接口静态工厂或策略方法封装共享规则。
继续比较接口 default 方法与抽象类中可覆写实现的边界。

## 复现
TAG=latest scripts/run-example.sh java L1-010-interface-methods
