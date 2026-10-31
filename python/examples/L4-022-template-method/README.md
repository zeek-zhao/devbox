# L4-022-template-method

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-22：父类固定算法骨架，把可变步骤留给子类实现。

可观察判据：基类 `run()` 固定顺序并调用抽象 `step()`，两个子类输出固定骨架。

## 为什么这样写

`Pipeline.run()` 三行固定准备、执行、校验顺序；其中 `self.step()` 行通过抽象接口动态分派。
两个子类只实现 `step()`，不覆盖 `run()`；调用方遍历基类类型的集合，统一调用骨架。
去掉动态步骤调用，第二、五行不再分别包含 `PYTHON`、`nohtyp`；
交换父类准备与校验行，两组输出的首尾都会交换。骨架输出来自父类而不是子类重复打印。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-022-template-method
