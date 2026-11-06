package main

import (
	"errors"
	"fmt"
	"time"
)

// 重试与退避：只重试「可重试」的错误（错误自己声明），有限次数 + 指数退避，
// 重试预算耗尽后把最后一次错误连同尝试次数一起报出去。

type RateLimitError struct{ Attempt int }

func (e *RateLimitError) Error() string {
	return fmt.Sprintf("rate limited at attempt %d", e.Attempt)
}
func (e *RateLimitError) Retryable() bool { return true }

type QuotaError struct{}

func (e *QuotaError) Error() string   { return "quota exceeded" }
func (e *QuotaError) Retryable() bool { return false }

// Retryable 让错误自己声明「这次失败值得再试吗」。
type Retryable interface {
	Retryable() bool
}

func isRetryable(err error) bool {
	var r Retryable
	return errors.As(err, &r) && r.Retryable()
}

// callWithRetry：最多 4 次尝试；退避 10ms 起步翻倍。waited 是累计退避时长
// （累加计划值，不测墙钟，保证输出确定）。
func callWithRetry(call func(int) error) (attempts int, waited time.Duration, err error) {
	delay := 10 * time.Millisecond
	for attempt := 1; ; attempt++ {
		err = call(attempt)
		attempts = attempt
		if err == nil {
			return attempts, waited, nil
		}
		if !isRetryable(err) {
			return attempts, waited, fmt.Errorf("not retryable: %w", err)
		}
		if attempt >= 4 {
			return attempts, waited, fmt.Errorf("gave up after %d attempts: %w", attempt, err)
		}
		waited += delay
		time.Sleep(delay)
		delay *= 2
	}
}

func flakyUntil(okAt int) func(int) error {
	return func(attempt int) error {
		if attempt < okAt {
			return &RateLimitError{Attempt: attempt}
		}
		return nil
	}
}

func main() {
	// 1) 第 3 次成功：两次退避 10ms+20ms
	attempts, waited, err := callWithRetry(flakyUntil(3))
	fmt.Printf("retry success: attempts=%d waited=%v err=%v\n", attempts, waited, err)

	// 2) 不可重试错误：第一次就停，不烧重试预算
	attempts, waited, err = callWithRetry(func(int) error { return &QuotaError{} })
	fmt.Printf("retry non-retryable: attempts=%d waited=%v err=%v\n", attempts, waited, err)

	// 3) 一直限流：预算耗尽，报最后一次错误与尝试次数
	attempts, waited, err = callWithRetry(flakyUntil(99))
	fmt.Printf("retry give-up: attempts=%d waited=%v err=%v\n", attempts, waited, err)
}
