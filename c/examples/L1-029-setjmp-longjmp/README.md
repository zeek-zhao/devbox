<!-- coverage: exempt 返回值和状态机足以处理服务错误，无非局部跳转需要。 -->

# L1-029-setjmp-longjmp —— 用非局部跳转传递错误状态

## 考点

- `setjmp` 首次直接返回 0。
- `longjmp` 恢复保存的执行环境，使 `setjmp` 返回传入的非零值。

## 为什么这么写

错误函数通过 `longjmp` 传回状态 7，调用端分别打印初次返回值与恢复后的值，避免把两种返回语义记反。

## 易错点

- 跳过的栈帧中的局部对象生命周期已经结束，不能继续使用其地址。
- 在 `setjmp` 与 `longjmp` 之间被修改且非 `volatile` 的局部自动变量，其值可能不确定。

## 运行

```bash
TAG=latest scripts/run-example.sh c L1-029-setjmp-longjmp
```
