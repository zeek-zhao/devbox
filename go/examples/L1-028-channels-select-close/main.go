package main

import "fmt"

func main() {
	unbuffered := make(chan string)
	sent := make(chan struct{})
	go func() {
		unbuffered <- "handshake"
		close(sent)
	}()
	fmt.Println("unbuffered:", <-unbuffered)
	<-sent

	buffered := make(chan int, 2)
	buffered <- 4
	buffered <- 7
	close(buffered)

	total := 0
	count := 0
	for value := range buffered {
		total += value
		count++
	}
	fmt.Printf("closed range: count=%d total=%d\n", count, total)

	value, ok := <-buffered
	fmt.Printf("closed receive: value=%d ok=%t\n", value, ok)

	ready := make(chan string, 1)
	ready <- "queued"
	select {
	case value := <-ready:
		fmt.Println("select ready:", value)
	default:
		fmt.Println("select ready: default")
	}

	empty := make(chan int)
	select {
	case <-empty:
		fmt.Println("select empty: received")
	default:
		fmt.Println("select empty: default")
	}
}
