# L3-005-ctypes-libc


## 考点
对应 KP-PY-L3-05：通过 `ctypes` 调用系统 C 库并声明函数签名。
固定字节输入的长度与 `strlen` 返回值一致，说明 ABI 参数和返回类型明确。

## 易错点
未声明 `argtypes` 和 `restype` 会导致参数错误转换甚至崩溃。
核对 C ABI 类型并限制输入为固定、NUL 结尾的安全字节串。

## 延伸
为系统接口实验补充空指针及边界长度的受控测试。
评估跨平台库加载差异，并把原生接口封装在窄边界内。

## 复现
TAG=latest scripts/run-example.sh python L3-005-ctypes-libc
