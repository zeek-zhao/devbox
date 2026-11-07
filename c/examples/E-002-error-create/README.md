# E-002-error-create —— 创建与抛出（错误值构造）

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-002 创建与抛出），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

函数失败时有的返回 -1、有的返回 0、有的直接打印后返回 void，调用方拿到返回值
分不清「这是失败码还是正常结果」，错误路径与成功路径混在同一种返回值里。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-002-error-create
docker run --rm -v "$PWD":/work -w /work/c/examples/E-002-error-create \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：1 行成功路径 + 3 行错误路径，错误行固定带
`code / what / detail` 三要素。

## 为什么这样处理

- 统一「返回错误值」这一种抛出形态：`code==0` 即成功，调用方的判定方式唯一。
- `what` 是稳定的机器可读标识（供上游精确匹配与测试断言），`detail` 是人读上下文
  （可自由措辞）。两者分离后，改提示文案不会破坏上游匹配。
- 校验分支各自给出独立的码与 what，避免「一个万能 INVALID 码」掩盖具体原因。

## 反例

- `return -1;`：调用方只看到失败，看不到是哪类失败，无法决定重试还是修调用。
- 错误信息只进 `fprintf(stderr)`、返回值仍为 0：日志里看着有错，程序语义却是成功，
  上游照样往下走（吞错的前奏，见 E-008）。
