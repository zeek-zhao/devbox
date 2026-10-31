package main

import "fmt"

func queryCount() (count int) {
	count = 2
	defer fmt.Printf("defer first registered, argument: %d\n", count)
	defer func() {
		fmt.Printf("defer second registered, captured: %d\n", count)
		count++
	}()
	count = 5
	fmt.Printf("body count: %d\n", count)
	return count
}

func main() {
	count := queryCount()
	fmt.Printf("caller count: %d\n", count)
}
