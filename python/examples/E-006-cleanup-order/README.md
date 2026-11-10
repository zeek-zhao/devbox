# E-006-cleanup-order —— 错误路径清理顺序

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-006 错误路径清理顺序），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

中途失败的批量操作把资源状态留在半途：文件句柄、锁、临时目录没有释放，
且清理顺序与获取顺序不一致时会互相踩踏（先关外层再关内层导致内层清理
失败）。只测正常路径的代码看不见这些问题——错误路径的清理才是排障现场。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-006-cleanup-order
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-006-cleanup-order \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：两个资源 a、b 依次打开，中途失败后按
**后开先关**（close: b 先于 close: a）逆序回滚，异常随后才被外层捕获；
可选项的清理失败用 `contextlib.suppress` 吞掉后继续，末行固定输出续跑记录。

## 为什么这样处理

- `contextlib.ExitStack` 把「打开 N 个资源」与「逆序关闭 N 个资源」绑成
  一对：异常在哪一步发生，已打开的资源都按获取的逆序回滚，顺序保证由
  栈结构给出，不靠手写列表。
- 清理代码不判断「是否该清理」——`with` 块无论正常退出还是异常退出都会
  走 `__exit__`，错误路径天然被覆盖。
- `suppress(ValueError)` 只吞明确声明的清理类异常且吞掉后要留下记录；
  这是「有意的吞」，与裸 `except: pass` 的「无意的吞」本质不同。

## 反例

- 在失败分支里手写 `resource.close()`：新增第三个资源后漏一条，错误路径
  泄漏，而正常路径测试全绿。
- 清理顺序与获取顺序相同：依赖项先被关掉，后续清理在坏状态上再炸一次，
  掩盖原始故障。
- 用裸 `except: pass` 吞清理异常且不留记录：故障消失，排障无据可查。
