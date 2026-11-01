# L4-001-singleton

<!-- coverage: exempt Api.create 必须建立独立内存库；进程全局单例会让测试和同进程服务实例串数据，且没有需唯一实例的可变配置 -->

## 考点

对应 KP-JV-L4-01：同一类型全局只存在一个实例，所有取用点看到同一份状态。

可观察判据：用私有构造器加静态 holder 类（或 enum 单例）；两次取引用 `==` 为真，反射调用私有构造器抛 `IllegalAccessException`。

## 为什么这样写

`src/Main.java` 第 21–33 行的 `Config` 私有构造器与 `Holder.INSTANCE` 负责唯一实例，
`main` 两次调用 `instance()` 后比较引用，再经第一份引用写入、第二份引用读取状态。
若改成每次创建新对象，`same instance: true` 和 `second value: shared` 都会改变。
`Config` 是独立顶层类，`Main` 不是可访问其私有成员的嵌套同伴；
第 11–17 行的反射不调用 `setAccessible`，真实捕获 `IllegalAccessException`，意外成功则抛断言错误。
若构造器变为可访问，最后一行不会出现且进程失败。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-001-singleton
```
