package main

import (
	"errors"
	"fmt"
	"strings"
)

// 反模式对照：同一底层错误，反模式写法产生错误决策，正解产生正确决策。
// 每组「反模式 → 正解」成对输出，便于逐行对照。

var ErrMaintenance = errors.New("under maintenance")
var ErrDiskFull = errors.New("disk full")

func upstream() error { return ErrMaintenance }

func doWorkPanics() int {
	panic("unexpected nil config: programmer bug")
}

func doWorkErrors() error { return ErrDiskFull }

func main() {
	err := fmt.Errorf("gateway: %w", upstream())

	// 1) 反模式：按文本判定——用的是另一处硬编码的旧文案，已与错误文本漂移
	byText := strings.Contains(err.Error(), "maintenance window")
	// 1) 正解：errors.Is 沿链判定身份，文本怎么改都不影响
	byIs := errors.Is(err, ErrMaintenance)
	fmt.Printf("antipattern match-by-text: %t / correct errors.Is: %t\n", byText, byIs)

	// 2) 反模式：吞错——失败被伪装成成功
	swallowed := func() error {
		_ = upstream()
		return nil
	}()
	// 2) 正解：理解不了就原样上抛
	raised := upstream()
	fmt.Printf("antipattern swallow: err==nil=%t / correct return: err==nil=%t\n",
		swallowed == nil, raised == nil)

	// 3) 反模式：中间层抢着记日志（边界还会再记一次，一条错误两份日志）
	midLayerLogs := 0
	func() {
		if upstream() != nil {
			midLayerLogs++
		}
	}()
	// 3) 正解：只在最终边界记一次
	fmt.Printf("antipattern double-log: mid-layer logs=%d / correct: log once at boundary\n",
		midLayerLogs)

	// 4) 反模式：panic 当流程控制——调用方只能 recover 出零值，拿不到 error 语义
	panicky := func() (n int) {
		defer func() { _ = recover() }()
		return doWorkPanics()
	}()
	// 4) 正解：返回 error，调用方按错误处理
	graceful := doWorkErrors()
	fmt.Printf("antipattern panic-control: recovered n=%d / correct err=%v\n", panicky, graceful)
}
