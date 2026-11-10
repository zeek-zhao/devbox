#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || {
  echo "[assert] run.sh 退出码非 0：rc=$rc"
  fail=1
}
grep -q '^utf8_write hex=E4BDA0E5A5BD char_len=2$' <<<"$out" ||
  {
    echo "[assert] 未命中 utf8mb4 正确写入行"
    fail=1
  }
grep -q '^latin1_write client_encode_fail=yes$' <<<"$out" ||
  {
    echo "[assert] 未命中客户端编码失败行"
    fail=1
  }
grep -q '^mojibake_stored hex=C3A4C2BDC2A0C3A5C2A5C2BD$' <<<"$out" ||
  {
    echo "[assert] 未命中双重编码落库指纹行"
    fail=1
  }
grep -qF "mojibake_read body='ä½\xa0å¥½' char_len=6" <<<"$out" ||
  {
    echo "[assert] 未命中乱码读回行"
    fail=1
  }
grep -q "^latin1_read_loss body='??' char_len=2$" <<<"$out" ||
  {
    echo "[assert] 未命中 latin1 读回降级行"
    fail=1
  }
grep -q '^column_latin1 err=1366 class=charset retryable=no$' <<<"$out" ||
  {
    echo "[assert] 未命中 1366 字符集列错误行"
    fail=1
  }
grep -q '^fixed roundtrip=yes hex_match=yes$' <<<"$out" ||
  {
    echo "[assert] 未命中 HEX 校验修复行"
    fail=1
  }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || {
  echo "ASSERT-FAIL"
  exit 1
}
