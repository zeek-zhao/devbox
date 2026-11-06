package main

import (
	"errors"
	"fmt"
	"strings"
)

// 不吞错与重抛：中间层不理解错误时必须带着自己的上下文原样重抛；
// 吞错（置 nil）与「只记日志不返回」都会让调用方把失败当成功。

var ErrCacheMiss = errors.New("cache miss")

func fetchFromCache() error { return ErrCacheMiss }

// 反例 1：吞错——把 err 置回 nil，调用方以为成功。
func loadSwallow() error {
	err := fetchFromCache()
	if err != nil {
		err = nil // 「先这样，回头再处理」
	}
	return err
}

// 反例 2：只记日志不返回——调用方看到的还是成功，日志成了唯一证据。
func loadLogOnly(logs *[]string) error {
	err := fetchFromCache()
	if err != nil {
		*logs = append(*logs, "ERROR load: cache miss")
		return nil
	}
	return nil
}

// 正确：不理解就带上下文重抛，身份不变。
func loadGood() error {
	if err := fetchFromCache(); err != nil {
		return fmt.Errorf("load: %w", err)
	}
	return nil
}

func main() {
	// 1) 吞错：调用方看到成功
	fmt.Printf("swallow: caller sees success=%t (cache miss lost)\n", loadSwallow() == nil)

	// 2) 只记日志不返回：同样是「假成功」，日志成了唯一线索
	var logs []string
	fmt.Printf("log-only: caller sees success=%t log=%q\n",
		loadLogOnly(&logs) == nil, strings.Join(logs, ";"))

	// 3) 正确重抛：错误带上下文继续向上
	err := loadGood()
	fmt.Printf("reraise: err=%v\n", err)

	// 4) 重抛不换身份：上游仍能按 sentinel 判定并决定重试/降级
	fmt.Printf("reraise keeps identity: errors.Is(err, ErrCacheMiss)=%t\n",
		errors.Is(err, ErrCacheMiss))
}
