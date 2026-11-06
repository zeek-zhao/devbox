package main

import (
	"errors"
	"fmt"
)

// 错误分类与类型体系：用不同的自定义错误类型表达不同「类别」，
// 类别（而不是具体错误实例）决定上层的处理策略：
// VALIDATION 修调用方输入、TRANSIENT 可重试、INTERNAL 快速失败。

// ValidationError 表示调用方输入问题，不该重试。
type ValidationError struct {
	Field string
	Value int
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("field %q invalid value %d", e.Field, e.Value)
}

// TransientError 表示环境临时问题，可重试。
type TransientError struct {
	Op      string
	Attempt int
}

func (e *TransientError) Error() string {
	return fmt.Sprintf("op %s failed at attempt %d", e.Op, e.Attempt)
}

// InternalError 表示程序自身 bug，快速失败。
type InternalError struct {
	Component string
}

func (e *InternalError) Error() string {
	return "internal bug in " + e.Component
}

func validate(age int) error {
	if age < 0 {
		return &ValidationError{Field: "age", Value: age}
	}
	return nil
}

func fetch(op string, attempt int) error {
	return &TransientError{Op: op, Attempt: attempt}
}

func load(component string) error {
	return &InternalError{Component: component}
}

// classify 把任意 error 归到唯一类别；归不进已知类型的按 INTERNAL 保守处理。
func classify(err error) string {
	var v *ValidationError
	var t *TransientError
	switch {
	case errors.As(err, &v):
		return "VALIDATION"
	case errors.As(err, &t):
		return "TRANSIENT"
	default:
		return "INTERNAL"
	}
}

func actionFor(category string) string {
	switch category {
	case "VALIDATION":
		return "reject-input"
	case "TRANSIENT":
		return "retry"
	default:
		return "fail-fast"
	}
}

func main() {
	errs := []error{validate(-1), fetch("fetch-user", 2), load("kv-store")}
	counts := map[string]int{}
	for _, err := range errs {
		category := classify(err)
		counts[category]++
		fmt.Printf("%s -> category=%s action=%s\n", err.Error(), category, actionFor(category))
	}
	fmt.Printf("taxonomy types=3 VALIDATION=%d TRANSIENT=%d INTERNAL=%d\n",
		counts["VALIDATION"], counts["TRANSIENT"], counts["INTERNAL"])
}
