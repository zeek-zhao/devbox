# E-009-charset-mojibake —— 字符集错配：乱码落库、1366 与 HEX 校验修复

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-009 字符集错配的检测与修复），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「输入输出边界校验」（`E-009-errno-boundary`）主题的 db 轨落地：
连接字符集是客户端与库之间的编码契约，契约破裂有两种形态——当场炸（1366 /
客户端编码错误）和**不炸但数据坏**（乱码落库、读回丢失）。后者更危险，因为它不报错。

## 现象

连接声明 `latin1` 时：多字节文本在客户端编码阶段就抛 `UnicodeEncodeError`
（根本没到库）；绕过编码层把「乱码字符串」写进 utf8mb4 列，字节被当成 latin1
再转一层，落库即**双重编码**（`C3A4C2BD...`，HEX 指纹当场不符，读回的是
`'ä½ å¥½'` 六个字符——不是中文）；好字节（`E4BDA0E5A5BD`）从 latin1 连接
读回时，服务端把不可转换字符降级成 `?`——信息已经丢了。往真正的 latin1 列
写中文，strict 模式直接报 `1366`（Incorrect string value）。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-009-charset-mojibake
# 或单独跑断言：
bash db/examples/E-009-charset-mojibake/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`utf8_write hex=E4BDA0E5A5BD char_len=2` →
`latin1_write client_encode_fail=yes` → 双重编码
`mojibake_stored hex=C3A4C2BDC2A0C3A5C2A5C2BD` →
`mojibake_read body='ä½ å¥½' char_len=6` → 好字节坏读
`latin1_read_loss body='??' char_len=2` → `column_latin1 err=1366
class=charset retryable=no` → `fixed roundtrip=yes hex_match=yes`。

## 为什么这样处理

- 验收字符集链路看 **HEX 指纹**（`E4BDA0E5A5BD`）而不是肉眼看字——
  乱码的肉眼形态随终端 / 驱动版本漂移，HEX 是字节级契约。
- 双重编码靠 HEX 指纹当场识别：落库字节 `C3A4C2BD...` ≠ 期望的
  `E4BDA0E5A5BD`；肉眼看到的「乱码长什么样」随终端漂移，字节不会。
- 好字节从坏连接读回（`??`）是**不可逆丢失**：服务端已把 utf8mb4 降级转码成
  latin1 的 `?`，原字符回不来；「能查出来」不等于「数据没坏」。
- 1366 归为 charset 类、`retryable=no`：列的字符集不会因为重试改变，
  修复动作是改列字符集（`CONVERT TO CHARACTER SET`）或改连接字符集。

## 反例

- 用「肉眼看是中文」验收跨字符集链路——终端帮你兜了底，库里的字节早坏了。
- 出现 1366 就把列改成 latin1「让写入过去」——错误被转成静默数据丢失。
- 连接字符串不写 charset、指望驱动默认值——驱动版本一升级契约就断。

## 依赖服务

`mysql`

## 命名空间

`db_e_009_charset_mojibake`
