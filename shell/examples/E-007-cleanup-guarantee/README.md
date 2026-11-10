# E-007-cleanup-guarantee —— 清理保证与退出码不被清理顶替

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-007 清理保证），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

两种清理事故：失败路径上没人清理——临时目录、锁文件、后台进程残留，
下次运行撞上脏状态；清理把失败"修没了"——收尾清理本身失败或清理后
`exit 0`，业务失败被顶替成清理的结果，上层看到既不是成功也不是业务错误。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-007-cleanup-guarantee
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-007-cleanup-guarantee \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：right-mode 业务退出码 3 原样保留；
wrong-mode 观察到 1（业务 3 被收尾清理的失败顶替）。

## 为什么这样处理

- 正确形态用 `trap cleanup EXIT`：清理挂在退出事件上，成功、失败、被信号打断
  都会跑；清理函数只清资源、只写日志，不 exit 不改码。
- bash 的 EXIT trap 不改写退出码（除非 trap 里显式 exit）——业务码 3 穿过
  清理原样冒出，这是「清理与错误传播解耦」的关键语义。
- 反面教材把清理写成最后一条命令：它自己失败（退出码 1）就成了整个脚本的
  退出码，业务 3 从此不可见，上层按 3 分派的处理逻辑全部落空。

## 反例

- `cmd || { cleanup; exit 0; }`：清理后显式退出 0，失败被洗成成功，假绿。
- 不挂 trap、只在成功路径末尾清理：任何一条失败/中断路径都漏。
- 清理函数里再 `exit`：清理失败直接顶替业务失败，误报方向都变了。
