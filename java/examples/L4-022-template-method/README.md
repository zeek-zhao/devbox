# L4-022-template-method

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-22：父类固定算法骨架，把可变步骤留给子类实现。

可观察判据：基类 `final run()` 固定顺序，两个子类实现抽象步骤。

## 为什么这样写

`src/Main.java` 的 `Pipeline.run` 声明为 `final`，方法体只按
`prepare(); execute(); verify();` 的固定顺序调用三个抽象步骤。
`MemoryPipeline`、`FilePipeline` 仅覆盖步骤，`main` 用 `Pipeline` 基类引用
调用骨架，六行标签实际来自动态分派到子类的方法。
如果交换骨架中的步骤，两个三行组都会改变顺序；如果去掉执行步骤，
两条 `execute` 输出都会消失。
`final` 的不可覆盖性是编译期约束，不能仅靠这些 stdout 证明：
子类若声明 `void run()`，编译器会报覆盖 final 方法错误，而不是运行时发现。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-022-template-method
```
