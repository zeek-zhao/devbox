# E-007-goto-cleanup —— 资源清理（goto 统一出口）

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-007 资源清理），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

函数里依次申请 buf、handle、lock 三个资源，在第三步失败时提前 return——
前两步的资源没人释放：句柄泄漏、内存泄漏只在压测/长跑时以偶发故障形式出现，
代码评审肉眼难查。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-007-goto-cleanup
docker run --rm -v "$PWD":/work -w /work/c/examples/E-007-goto-cleanup \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：成功路径申请/释放三个资源各一次；失败路径（加锁失败）
不释放未持有的锁、但按逆序释放 handle 与 buf，两条路径都落到统一出口打印 rc。

## 为什么这样处理

- 所有资源变量先初始化为「未持有」，错误路径 `goto cleanup` 跳到唯一出口；
  出口按申请逆序、只释放已持有的资源——释放逻辑只有一份，不存在「某个分支忘了写」。
- 释放后立刻置空/复位，重复进入出口也不会双重释放（与 L1-023 的防双重释放纪律衔接）。
- 失败路径的打印顺序本身就是断言对象：release lock 不出现、release handle/release buf
  逆序出现。

## 反例

- 每个错误点各自手写一遍释放序列：分支多了必然漏一处，且 diff 无法发现。
- 失败时直接 `return` 不清理：泄漏被 CI 的短进程掩盖，长跑服务上变成慢性故障。
