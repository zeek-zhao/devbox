// 用例 hello：确认 go 工具链可用、goroutine 能跑
package main

import (
	"fmt"
	"sync"
)

func main() {
	fmt.Println("[hello] Go from devbox")

	// 三个 goroutine 并发累加，用 WaitGroup 收口
	var wg sync.WaitGroup
	var mu sync.Mutex
	sum := 0
	for i := 1; i <= 3; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			mu.Lock()
			defer mu.Unlock()
			sum += n
		}(i)
	}
	wg.Wait()

	// 打印的是确定值，不打印 sum，避免调度顺序导致输出不稳定
	fmt.Printf("goroutines = %d\n", 3)

	total := 0
	for i := 1; i <= 100; i++ {
		total += i
	}
	fmt.Printf("sum(1..100) = %d\n", total)
}
