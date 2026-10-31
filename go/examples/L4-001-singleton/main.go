package main

import (
	"fmt"
	"sync"
)

type Config struct {
	Mode string
}

var (
	once      sync.Once
	instance  *Config
	initCalls int
)

func GetConfig() *Config {
	once.Do(func() {
		initCalls++
		instance = &Config{Mode: "default"}
	})
	return instance
}

func main() {
	var configs [2]*Config
	var wg sync.WaitGroup
	start := make(chan struct{})
	for i := range configs {
		wg.Add(1)
		go func(index int) {
			defer wg.Done()
			<-start
			configs[index] = GetConfig()
		}(i)
	}
	close(start)
	wg.Wait()

	fmt.Printf("same instance: %t\n", configs[0] == configs[1])
	fmt.Printf("init calls: %d\n", initCalls)
	// 取用完成后串行改状态，避免把可变配置的数据竞争混入单例示例。
	configs[0].Mode = "production"
	fmt.Printf("shared mode: %s\n", configs[1].Mode)
}
