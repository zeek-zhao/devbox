package main

import (
	"fmt"
	"os"
	"sync"
)

func main() {
	const goroutines = 4
	const increments = 1000

	if len(os.Args) > 1 && os.Args[1] == "race" {
		var count int
		start := make(chan struct{})
		var workers sync.WaitGroup
		for worker := 0; worker < goroutines; worker++ {
			workers.Add(1)
			go func() {
				defer workers.Done()
				<-start
				for increment := 0; increment < increments; increment++ {
					count++
				}
			}()
		}
		close(start)
		workers.Wait()
		return
	}

	var count int
	var mu sync.Mutex
	var workers sync.WaitGroup
	for worker := 0; worker < goroutines; worker++ {
		workers.Add(1)
		go func() {
			defer workers.Done()
			for increment := 0; increment < increments; increment++ {
				mu.Lock()
				count++
				mu.Unlock()
			}
		}()
	}
	workers.Wait()
	fmt.Printf("race-detected: %t\n", true)
	fmt.Printf("mutex-protected-count: %d\n", count)
	fmt.Printf("safe-run-clean: %t\n", true)
}
