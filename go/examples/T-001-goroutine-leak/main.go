// T-001-goroutine-leak 练习现场（有缺陷代码，勿模仿）。
// 缺陷 1：goroutine 泄漏 —— handleRequest 往无缓冲 channel 发送且永远无人接收，每个请求泄漏一个永远阻塞在 chan send 的 goroutine（高峰后不回落）。
// 缺陷 2：数据竞争 —— 多个 goroutine 并发 counter++，无任何同步。
// 观测钩子：LEAK_DUMP=1 按 debug=2 打 goroutine 栈快照；LEAK_PPROF=<路径> 写 pprof proto 格式 goroutine profile（供 go tool pprof 聚合分析）。
package main

import (
	"fmt"
	"os"
	"runtime"
	"runtime/pprof"
	"time"
)

var counter int // 缺陷 2：无锁共享

func handleRequest(id int, results chan<- int) {
	counter++     // 缺陷 2：数据竞争（-race 报 WARNING: DATA RACE）
	results <- id // 缺陷 1：无缓冲且无人接收 → 永远阻塞在 chan send
}

func main() {
	fmt.Println("leak: start") // 执行标记：证明二进制真的被跑过（素材 S-06）
	before := runtime.NumGoroutine()
	const n = 100
	results := make(chan int) // 缺陷根源：无缓冲，且全程没有接收方
	for i := 0; i < n; i++ {
		go handleRequest(i, results) // 每个请求 spawn 一个，从不回收
	}
	time.Sleep(300 * time.Millisecond) // 让 worker 都跑到阻塞点（真实事故里就是「高峰后不降」）
	after := runtime.NumGoroutine()
	fmt.Printf("leak: goroutines before=%d after=%d delta=%d\n", before, after, after-before)

	if p := os.Getenv("LEAK_PPROF"); p != "" {
		f, err := os.Create(p)
		if err != nil {
			fmt.Println("pprof: 写 profile 失败:", err)
			os.Exit(2)
		}
		if err := pprof.Lookup("goroutine").WriteTo(f, 0); err != nil {
			fmt.Println("pprof: 序列化失败:", err)
			_ = f.Close()
			os.Exit(2)
		}
		_ = f.Close()
		fmt.Println("pprof: goroutine profile 已写入", p)
	}
	if os.Getenv("LEAK_DUMP") == "1" {
		fmt.Println("dump: goroutine 栈快照（debug=2）")
		_ = pprof.Lookup("goroutine").WriteTo(os.Stdout, 2)
	}

	if after-before >= 90 { // 观测判据：100 个 worker 里 ≥90 个仍活着 = 泄漏坐实
		fmt.Printf("LEAK-CONFIRMED: %d goroutines still blocked (expect 0 leaked)\n", after-before)
		os.Exit(1)
	}
	fmt.Println("leak: clean")
}
