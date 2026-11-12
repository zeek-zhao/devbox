package main

import (
	"errors"
	"fmt"
)

// 错误身份判定：errors.Is 回答「是不是那个错误」，errors.As 回答
// 「是不是那一类错误」并把具体类型取出来；errors.New 每次创建新实例，
// 文本相同身份也不同——sentinel 必须全仓复用同一实例。

var ErrUnauthorized = errors.New("unauthorized")

// ParseError 是「一类」错误：字段、行号不同是不同实例，但可统一提取处理。
type ParseError struct {
	Field string
	Line  int
}

func (e *ParseError) Error() string {
	return fmt.Sprintf("parse error at line %d: field %q", e.Line, e.Field)
}

func parse(line int) error {
	return fmt.Errorf("config: %w", &ParseError{Field: "age", Line: line})
}

func main() {
	// 1) errors.New 每次新实例：文本相同，身份不同
	a := errors.New("unauthorized")
	b := errors.New("unauthorized")
	fmt.Printf("identity: two errors.New with same text identical: %t\n", a == b)

	// 2) sentinel 全仓复用同一实例：包装后仍能确认同一身份
	fmt.Printf("identity: wrapped sentinel via errors.Is: %t\n",
		errors.Is(fmt.Errorf("auth: %w", ErrUnauthorized), ErrUnauthorized))

	// 3) errors.As 从包装链里取出具体类型，拿到结构化字段
	var pe *ParseError
	err := parse(3)
	ok := errors.As(err, &pe)
	fmt.Printf("as: extracted *ParseError ok=%t field=%q line=%d\n", ok, pe.Field, pe.Line)

	// 4) 同类不同值：两个 ParseError 都是「这一类」，值各自保留
	err2 := fmt.Errorf("retry: %w", &ParseError{Field: "age", Line: 9})
	var pe2 *ParseError
	ok2 := errors.As(err2, &pe2)
	fmt.Printf("as: second same-class ok=%t field=%q line=%d\n", ok2, pe2.Field, pe2.Line)

	badIdentity := errors.New("unauthorized")
	goodIdentity := fmt.Errorf("auth: %w", ErrUnauthorized)
	fmt.Printf("antipattern=error-identity bad=%t good=%t\n",
		errors.Is(badIdentity, ErrUnauthorized), errors.Is(goodIdentity, ErrUnauthorized))
}
