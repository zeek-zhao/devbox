<!-- coverage: pending -->

# L1-002 —— 整型提升与常规算术转换

两个 `unsigned char` 操作数先提升为 `int`，再做加法，因此结果是 300 而不是在 8 位
范围内先回绕成 44。
