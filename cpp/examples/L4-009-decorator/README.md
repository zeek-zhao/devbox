# L4-009-decorator


## 考点

对应 KP-L4-09：用包装对象在运行时叠加职责，替代为每种组合派生一个子类。

可观察判据：两层装饰器包住同一组件，`describe()` 输出按包装顺序拼接的固定文本；组件本体行为不变。

## 为什么这样写

`main.cpp` 第 17–27 行的装饰器也实现组件接口，并持有只读的组件基类指针。
第 29–43 行的两种装饰器先委托内层虚函数，再在返回值外叠加自己的标签，不修改组件状态。
第 46–55 行对同一个基础组件建立两种包装顺序，通过基类指针调用并在前后读取本体。
若拆掉缓存层委托，`decorated: stats(cache(result))` 会丢掉 `result`；若交换包装顺序，则变成反向示例的 `cache(stats(result))`。若修改本体，`after: result` 将不再保持原样。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh cpp L4-009-decorator
```
