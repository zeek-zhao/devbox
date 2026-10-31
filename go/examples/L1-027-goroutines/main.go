package main

import "fmt"

func main() {
	result := make(chan int)
	go func() {
		documents := 3
		result <- documents * 2
	}()

	fmt.Println("main: waiting for task")
	count := <-result
	fmt.Printf("task result: %d\n", count)
	fmt.Println("main: result received")
}
