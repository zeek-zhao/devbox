# E-004-error-wrap —— 错误包装：追加上下文、保留退出码

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-004 错误包装），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

两层包装的三种事故：只 `return $?` 不加说明——上层只看到 22，不知道是在哪一步、
为干什么失败的；包装时换码（`return 1`）——底层靠 22 区分的失败类别在上层丢失；
包装时吞码——`cmd || return 0`，失败被包装层伪装成功。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-004-error-wrap
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-004-error-wrap \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：stdout 是失败链与保留的退出码；
stderr 上三层诊断都在（底层原始 `HTTP 404` + 两层各自的包装上下文）。

## 为什么这样处理

- 包装 = 接住码 + 追加一层「谁、在干什么时失败的」+ 原样 `return "$rc"`：
  退出码类别信息一路保留，诊断文本逐层堆叠成链。
- stderr 逐层追加而不是逐层重写：排障时从最外层读到最内层，
  每层只补一句自己的上下文。

## 反例

- `return 1`：底层 22（可对照 curl 手册定位）被换成万能 1，类别信息丢失。
- `cmd || return 0`：包装层变成吞错层，上层看到的全是成功。
- 只包文本不包码：`echo failed` 后继续跑，失败语义被稀释成日志。
