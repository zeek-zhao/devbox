package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// 超时与取消：context 把超时/取消统一变成 ctx.Err()（DeadlineExceeded /
// Canceled），业务调用在 select 里同时等结果与 ctx.Done()，
// 收到后用 %w 把取消原因沿错误链向上传播。

var ErrQuery = errors.New("query failed")

func query(ctx context.Context, work time.Duration) error {
	select {
	case <-time.After(work): // 模拟慢查询
		return nil
	case <-ctx.Done():
		return fmt.Errorf("query: %w", ctx.Err())
	}
}

func handle(parent context.Context, budget, work time.Duration) error {
	ctx, cancel := context.WithTimeout(parent, budget)
	defer cancel() // 无论成败都释放计时器资源
	if err := query(ctx, work); err != nil {
		return fmt.Errorf("handle: %w", err)
	}
	return nil
}

func main() {
	// 1) 超时路径：预算 10ms < 慢查询 50ms
	err := handle(context.Background(), 10*time.Millisecond, 50*time.Millisecond)
	fmt.Printf("timeout: err=%v\n", err)
	fmt.Printf("timeout identity: errors.Is(err, context.DeadlineExceeded)=%t\n",
		errors.Is(err, context.DeadlineExceeded))

	// 2) 取消路径：预算充足但调用方主动 cancel
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		time.Sleep(5 * time.Millisecond)
		cancel()
	}()
	err = handle(ctx, time.Second, 50*time.Millisecond)
	fmt.Printf("cancel: err=%v\n", err)
	fmt.Printf("cancel identity: errors.Is(err, context.Canceled)=%t\n",
		errors.Is(err, context.Canceled))

	// 3) 预算充足：正常完成
	err = handle(context.Background(), time.Second, 20*time.Millisecond)
	fmt.Printf("enough budget: err=%v\n", err)
}
