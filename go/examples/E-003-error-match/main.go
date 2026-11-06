package main

import (
	"errors"
	"fmt"
)

// 捕获与精确匹配：错误被包装一层后 == 必然失配，必须用 errors.Is 沿链匹配；
// 自定义错误类型还可以实现自己的 Is 方法，扩展匹配语义（按业务规则匹配）。

var ErrQuota = errors.New("quota exceeded")
var ErrNotFound = errors.New("record not found")

// OverdueError 携带逾期天数；两次逾期天数不同就不是同一个实例，
// 但「都超过 30 天」在业务上应视为同一类违约——用自定义 Is 表达这条规则。
type OverdueError struct {
	Days int
}

func (e *OverdueError) Error() string {
	return fmt.Sprintf("invoice overdue %d days", e.Days)
}

func (e *OverdueError) Is(target error) bool {
	t, ok := target.(*OverdueError)
	return ok && e.Days > 30 && t.Days > 30
}

func readRecord() error {
	return fmt.Errorf("read record: %w", ErrNotFound)
}

func main() {
	wrapped := fmt.Errorf("handle request: %w", readRecord())

	// 1) == 比较的是接口 identity：包装一层后失配
	fmt.Printf("match ==: wrapped == ErrNotFound: %t\n", wrapped == ErrNotFound)

	// 2) errors.Is 沿 Unwrap 链匹配到 sentinel
	fmt.Printf("match errors.Is(wrapped, ErrNotFound): %t\n", errors.Is(wrapped, ErrNotFound))

	// 3) 不相关的错误匹配失败
	fmt.Printf("match errors.Is(wrapped, ErrQuota): %t\n", errors.Is(wrapped, ErrQuota))

	// 4) 自定义 Is：45 天逾期匹配「逾期 30 天以上即违约」的判据
	heavy := fmt.Errorf("billing: %w", &OverdueError{Days: 45})
	policy := &OverdueError{Days: 31}
	fmt.Printf("match custom Is: 45-day overdue matches policy(30+): %t\n", errors.Is(heavy, policy))

	// 5) 自定义 Is：5 天逾期不构成违约
	light := fmt.Errorf("billing: %w", &OverdueError{Days: 5})
	fmt.Printf("match custom Is: 5-day overdue matches policy(30+): %t\n", errors.Is(light, policy))
}
