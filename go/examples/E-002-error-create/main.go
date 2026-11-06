package main

import (
	"errors"
	"fmt"
)

// 创建与抛出：静态错误用 errors.New；带数据的错误用 fmt.Errorf 的动词构造；
// 最大的坑是 typed-nil——具体指针类型的 nil 赋给 error 接口后，接口不等于 nil。

var ErrEmptyInput = errors.New("input empty")

type ConfigError struct {
	Port int
}

func (e *ConfigError) Error() string {
	return fmt.Sprintf("port %d out of range 1..65535", e.Port)
}

// 反例：成功路径返回具体指针类型的 nil。调用方把它赋给 error 接口后，
// 接口里装的是 (type=*ConfigError, value=nil)，err != nil 成立，误报失败。
func parsePortTyped(want int) *ConfigError {
	if want < 1 || want > 65535 {
		return &ConfigError{Port: want}
	}
	return nil
}

// 正确写法：函数签名用 error 接口，成功路径显式 return nil。
func parsePort(want int) error {
	if want < 1 || want > 65535 {
		return &ConfigError{Port: want}
	}
	return nil
}

func main() {
	// 1) errors.New：静态文本错误，同文本全仓复用可当 sentinel
	fmt.Printf("create errors.New: %q\n", ErrEmptyInput.Error())

	// 2) fmt.Errorf：动词携带数据，创建带上下文的新错误（没有 %w，只是创建不是包装）
	err := fmt.Errorf("connect %s attempt %d failed", "10.0.0.7:5432", 3)
	fmt.Printf("create fmt.Errorf: %q\n", err.Error())

	// 3) typed-nil 陷阱：明明没有错误，调用方却看到 err != nil
	var e2 error = parsePortTyped(80)
	fmt.Printf("typed-nil trap: ok case but err!=nil: %t\n", e2 != nil)

	// 4) 正确写法：error 签名 + 显式 return nil，成功即 err == nil
	fmt.Printf("correct: return nil as error gives err==nil: %t\n", parsePort(80) == nil)

	// 5) 真正的错误实例：Error() 产出稳定的诊断行
	var bad error = parsePortTyped(70000)
	fmt.Printf("create custom type: %q\n", bad.Error())
}
