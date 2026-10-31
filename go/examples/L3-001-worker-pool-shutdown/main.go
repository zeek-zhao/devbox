package main

import (
	"context"
	"fmt"
	"sync"
)

func main() {
	const workerCount = 3
	jobs := make(chan int, 6)
	var workers sync.WaitGroup
	var once sync.Once
	var mu sync.Mutex
	onceCalls := 0
	processed := 0
	sum := 0

	for worker := 0; worker < workerCount; worker++ {
		workers.Add(1)
		go func() {
			defer workers.Done()
			for job := range jobs {
				once.Do(func() { onceCalls++ })
				mu.Lock()
				processed++
				sum += job
				mu.Unlock()
			}
		}()
	}

	for job := 1; job <= 6; job++ {
		jobs <- job
	}
	close(jobs)
	workers.Wait()

	parent, cancelParent := context.WithCancel(context.Background())
	child, cancelChild := context.WithCancel(parent)
	propagated := make(chan struct{})
	go func() {
		<-child.Done()
		close(propagated)
	}()
	cancelParent()
	<-propagated
	cancelChild()

	fmt.Printf("jobs-processed: %d\n", processed)
	fmt.Printf("job-sum: %d\n", sum)
	fmt.Printf("workers-exited: %t\n", true)
	fmt.Printf("once-calls: %d\n", onceCalls)
	fmt.Printf("cancel-propagated: %t\n", child.Err() == context.Canceled)
}
