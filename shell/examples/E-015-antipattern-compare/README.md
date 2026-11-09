# E-015-antipattern-compare —— 错误处理反模式对照

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-015 反模式对照），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

错误处理的坑很少以"报错"的形式出现，它们以"假绿"的形式出现：
失败被洗成成功、带空格路径被分词、管道中间命令的失败被吞、
诊断信息混进管道数据。这四种坑的共性是：**脚本还在跑、退出码还是 0**。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-015-antipattern-compare
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-015-antipattern-compare \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：四组对照，bad= 一侧就是坏写法的真实现象
（exit0 假绿、words=2 分词、exit0 管道吞错、pipeline-lines=1 诊断污染数据）。

## 为什么这样处理

- 对照实验而不是论述：坏写法直接跑给你看，bad=/good= 同屏并排，
  危害不需要想象。
- 四个坑各有对应正解（E-002 stderr 纪律、E-008 记录后重抛、
  S-12 pipefail 与引号纪律、L1-021 的 pipefail 语义），对照行是
  那些示例的"反面索引"。
- bad 一侧的数字都来自真实执行：不是编造的典型现象（素材纪律 S-12 类型②）。

## 反例

- "这里不会失败所以 || true"：哪一行的失败都不在计划内（E-008）。
- "路径是我控制的不会有空格"：变量展开加引号是零成本的纪律（S-12）。
- "管道只有最后一个命令重要"：pipefail 缺位让中间失败静默穿管（S-12）。
- "诊断打到哪都行"：下游管道消费 stdout 时诊断就是脏数据（E-002）。
