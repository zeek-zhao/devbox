package main

import (
	"errors"
	"fmt"
)

// 不可恢复与快速失败：库内部用 panic 表达「程序员 bug」（不变量被破坏），
// 在库边界 recover 一次并转成带 sentinel 的 error；进程边界对不可恢复错误
// 选择快速失败。为可断言性，本例用打印代替真实退出。

var ErrInvariant = errors.New("invariant violated")

// parseRoman 依赖符号表不变量；表被改坏（程序员 bug）时 panic，
// 不允许带着坏状态继续算出错误结果。
func parseRoman(s string) int {
	symbols := map[rune]int{'I': 1, 'V': 5, 'X': 10}
	total := 0
	for _, r := range s {
		v, ok := symbols[r]
		if !ok {
			panic(fmt.Sprintf("symbol table missing %q: programmer bug", string(r)))
		}
		total += v
	}
	return total
}

// 库边界：panic 最多被 recover 成 error，绝不作为 panic 穿透给调用方。
// panic 的具体文本只是诊断细节，对上契约是 sentinel ErrInvariant。
func parseRomanSafe(s string) (n int, err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("parse roman %q: %v: %w", s, r, ErrInvariant)
		}
	}()
	return parseRoman(s), nil
}

func main() {
	// 1) 正常输入
	n, err := parseRomanSafe("XVI")
	fmt.Printf("fail-fast normal: n=%d err=%v\n", n, err)

	// 2) 不变量被破坏：边界把 panic 转成 error，进程不崩
	n, err = parseRomanSafe("xyz")
	fmt.Printf("fail-fast recovered: n=%d err=%v\n", n, err)

	// 3) 不可恢复错误的处置：按 sentinel 分类后快速失败（打印代替真实 exit）
	if err != nil && errors.Is(err, ErrInvariant) {
		fmt.Println("fail-fast policy: unrecoverable -> exit(70) (simulated)")
	}

	// 4) 边界转换后契约仍可判定
	fmt.Printf("fail-fast boundary: panic converted, errors.Is(err, ErrInvariant)=%t\n",
		errors.Is(err, ErrInvariant))
}
