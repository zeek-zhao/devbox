# L4-022-template-method

<!-- coverage: pending -->

## 考点

对应 KP-GO-L4-22：父类固定算法骨架，把可变步骤留给子类实现。

可观察判据：用接口 + 组合模拟：骨架函数固定调用顺序，两个实现输出固定骨架。

## 为什么这样写

Go 没有继承：`main.go` 第 5–17 行把可变步骤放入接口，
普通函数 `RunWorkflow` 固定 begin、准备、执行、校验、end 的顺序；
第 19–21 行的工作流组合步骤接口并委托骨架函数，不把骨架本身放入步骤接口。
第 23–49 行两个实现保存并修改不同类型的真实状态，
第 52–57 行调用方只运行工作流，不自行排列步骤。
若拆掉骨架中的执行步骤，`memory verify: true` 和 `text verify: true` 都会变成
false；若将执行放到准备之前，结果同样错误，且步骤输出顺序改变。
校验布尔值由状态比较得出，两组 begin/end 验证共享骨架。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh go L4-022-template-method
```
