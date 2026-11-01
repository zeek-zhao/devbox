

# L1-012 —— 置位、清位、翻转与测试

用 `SET_BIT`、`CLR_BIT`、`TGL_BIT`、`TST_BIT` 宏逐步修改并观察同一个无符号变量。
所有移位位置都小于 `unsigned int` 的位宽，避免移位未定义行为。
