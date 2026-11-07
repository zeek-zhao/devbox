package main

import (
	"errors"
	"fmt"
)

// 上下文附加：中间层用 fmt.Errorf 给错误附加「谁、对什么、做了什么」的上下文，
// 同时用 %w 保住错误身份；对外可见的数据用 %q 引住，防注入、防多行污染日志。

var ErrTimeout = errors.New("operation timed out")
var ErrNotFound = errors.New("user not found")

func dial(host string) error {
	return fmt.Errorf("dial %s: %w", host, ErrTimeout)
}

func loadProfile(user string) error {
	return fmt.Errorf("load profile %q: %w", user, dial("10.0.0.7:5432"))
}

func main() {
	// 1) 每层附加上下文后的完整诊断文本
	err := loadProfile("alice")
	fmt.Printf("context text: %v\n", err)

	// 2) 上下文只是壳，错误身份还在
	fmt.Printf("context keeps identity: errors.Is(err, ErrTimeout)=%t\n", errors.Is(err, ErrTimeout))

	// 3) 每层上下文都可以剥掉
	fmt.Printf("peel outer: %v\n", errors.Unwrap(err))
	fmt.Printf("peel inner: %v\n", errors.Unwrap(errors.Unwrap(err)))

	// 4) 对外数据用 %q 引住：恶意输入在日志里只占一行、不可注入
	row := "bobby; drop table users"
	safe := fmt.Errorf("lookup %q: %w", row, ErrNotFound)
	fmt.Printf("context quotes data: %v\n", safe)
	fmt.Printf("context quotes keeps identity: errors.Is(safe, ErrNotFound)=%t\n",
		errors.Is(safe, ErrNotFound))
}
