package main

import (
	"errors"
	"fmt"
	"sort"
	"sync"
)

// 并发错误聚合：多个 worker 各自报错，全部收集完再 errors.Join 成一个错误；
// 聚合错误保留每个成员的身份，errors.Is 对任一成员都成立；无失败时 Join 返回 nil。

var ErrDisk = errors.New("disk unavailable")
var ErrAuth = errors.New("auth rejected")

type Result struct {
	Shard int
	Err   error
}

func syncShard(s int) error {
	switch s {
	case 1:
		return ErrDisk
	case 3:
		return ErrAuth
	default:
		return nil
	}
}

func fanOut(shards []int) []error {
	results := make(chan Result, len(shards))
	var wg sync.WaitGroup
	for _, s := range shards {
		wg.Add(1)
		go func(s int) {
			defer wg.Done()
			results <- Result{Shard: s, Err: syncShard(s)}
		}(s)
	}
	wg.Wait()
	close(results)

	// 并发完成顺序不定：按分片号排序，保证聚合结果确定
	byShard := map[int]error{}
	for r := range results {
		if r.Err != nil {
			byShard[r.Shard] = fmt.Errorf("shard %d: %w", r.Shard, r.Err)
		}
	}
	keys := make([]int, 0, len(byShard))
	for k := range byShard {
		keys = append(keys, k)
	}
	sort.Ints(keys)

	var errs []error
	for _, k := range keys {
		errs = append(errs, byShard[k])
	}
	return errs
}

func main() {
	errs := fanOut([]int{0, 1, 2, 3})
	joined := errors.Join(errs...)
	fmt.Printf("join: err=%v\n", joined)

	fmt.Printf("join member disk: errors.Is(joined, ErrDisk)=%t\n", errors.Is(joined, ErrDisk))
	fmt.Printf("join member auth: errors.Is(joined, ErrAuth)=%t\n", errors.Is(joined, ErrAuth))
	fmt.Printf("join non-member: errors.Is(joined, other)=%t\n",
		errors.Is(joined, errors.New("unknown")))

	// 只有一个失败也能聚合（相比手工拼字符串不会丢结构）
	single := errors.Join(fmt.Errorf("shard 7: %w", ErrDisk))
	fmt.Printf("join single: err=%v\n", single)

	// 无失败：Join 返回 nil，调用方零分支
	fmt.Printf("join empty: err==nil=%t\n", errors.Join() == nil)
}
