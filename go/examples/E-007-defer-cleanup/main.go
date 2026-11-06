package main

import (
	"errors"
	"fmt"
	"io"
)

// 资源清理：defer 保证清理一定执行（包括错误路径）；但清理自身也会失败，
// 用命名返回值让 defer 把清理错误与主错误合成——主错误优先，清理错误不丢。

var ErrCloseFailed = errors.New("simulated close failure")
var ErrWriteFailed = errors.New("simulated write failure")

type failingWriteCloser struct{}

func (failingWriteCloser) Write([]byte) (int, error) { return 0, ErrWriteFailed }
func (failingWriteCloser) Close() error              { return ErrCloseFailed }

type failingCloser struct{}

func (failingCloser) Write(p []byte) (int, error) { return len(p), nil }
func (failingCloser) Close() error                { return ErrCloseFailed }

type goodWriteCloser struct{ closed bool }

func (g *goodWriteCloser) Write(p []byte) (int, error) { return len(p), nil }
func (g *goodWriteCloser) Close() error                { g.closed = true; return nil }

// persist 演示「主错误优先」的清理合成：defer 里关闭资源，
// 关闭失败只在主流程成功时才对外可见。
func persist(w io.WriteCloser, content string) (err error) {
	defer func() {
		if cerr := w.Close(); cerr != nil && err == nil {
			err = fmt.Errorf("cleanup: %w", cerr)
		}
	}()
	if _, werr := w.Write([]byte(content)); werr != nil {
		return fmt.Errorf("write: %w", werr)
	}
	return nil
}

func main() {
	// 1) 主错误优先：写失败 + 关失败 → 返回主错误，清理错误不覆盖它
	err1 := persist(failingWriteCloser{}, "data")
	fmt.Printf("primary first: %v\n", err1)

	// 2) 主流程成功、清理失败：清理错误对外可见，不静默丢掉
	err2 := persist(failingCloser{}, "data")
	fmt.Printf("cleanup visible: %v\n", err2)

	// 3) 全部成功：err 为 nil，且资源确实被关闭
	g := &goodWriteCloser{}
	err3 := persist(g, "data")
	fmt.Printf("all good: err==nil=%t closed=%t\n", err3 == nil, g.closed)

	// 4) defer 清理在错误路径同样执行
	steps := []string{}
	err4 := func() (err error) {
		steps = append(steps, "open")
		defer func() { steps = append(steps, "close") }()
		return errors.New("job failed")
	}()
	fmt.Printf("error path cleanup: steps=%v err=%v\n", steps, err4)
}
