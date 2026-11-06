package main

import (
	"errors"
	"fmt"
)

// 传播与包装：中间层用 %w 把底层错误包进来再往上抛，顶层既能看到完整调用链
// 文本，又能用 errors.Is/As 还原底层错误；用 %v 文本还在，但链断了。

var ErrDiskFull = errors.New("disk full")

func layer1() error { return ErrDiskFull }
func layer2() error { return fmt.Errorf("write segment: %w", layer1()) }
func layer3() error { return fmt.Errorf("commit log: %w", layer2()) }

func main() {
	// 1) 三层 %w 包装后的完整诊断文本
	err := layer3()
	fmt.Printf("wrapped text: %v\n", err)

	// 2) errors.Unwrap 剥一层
	fmt.Printf("unwrap once: %v\n", errors.Unwrap(err))

	// 3) %w 保留错误链：顶层仍能判定根因
	fmt.Printf("wrap %%w keeps chain: errors.Is(err, ErrDiskFull)=%t\n", errors.Is(err, ErrDiskFull))

	// 4) %v 断链对照：文本相似，但 errors.Is 判不到了
	noChain := fmt.Errorf("commit log: %v", layer2())
	fmt.Printf("wrap %%v loses chain: errors.Is(err, ErrDiskFull)=%t unwrap=nil: %t\n",
		errors.Is(noChain, ErrDiskFull), errors.Unwrap(noChain) == nil)
}
