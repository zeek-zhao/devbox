package main

import (
	"errors"
	"fmt"
	"log/slog"
	"os"
)

// 可观测性：错误在「边界」用结构化日志记一次（带 err 字段与关键属性）；
// 中间层只传播不记录。日志是给人的检索索引，返回值才是给程序的判定依据，
// 二者不要混用——记了日志不等于可以不返回错误，反之亦然。

var ErrRepoDown = errors.New("repo unavailable")

func repo() error { return ErrRepoDown }

func service() error {
	// 中间层：只加上下文传播，不记日志
	return fmt.Errorf("service: %w", repo())
}

// 反例：中间层也记一遍——同一次失败出现两条日志，且这条没有 err 字段。
func serviceDoubleLog(log *slog.Logger) error {
	if err := repo(); err != nil {
		log.Error("repo failed", "layer", "service")
		return err
	}
	return nil
}

func main() {
	// 确定性输出：文本协议 + 去掉时间戳
	h := slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		ReplaceAttr: func(_ []string, a slog.Attr) slog.Attr {
			if a.Key == slog.TimeKey {
				return slog.Attr{}
			}
			return a
		},
	})
	log := slog.New(h)

	// 1) 正确：边界记一次，err 字段 + 关键属性（op）
	err := service()
	if err != nil {
		log.Error("request failed", "err", err, "op", "list-users")
	}

	// 2) 反例：中间层再记，同一失败第二条第 err 缺失
	serviceDoubleLog(log)

	// 3) 日志不影响判定：返回的错误仍可 errors.Is
	fmt.Printf("observability: errors.Is after logging=%t\n", errors.Is(err, ErrRepoDown))
}
