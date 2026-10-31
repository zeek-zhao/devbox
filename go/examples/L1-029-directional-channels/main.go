package main

import "fmt"

func enqueue(output chan<- int, values []int) {
	for _, value := range values {
		output <- value
	}
}

func produce(values []int) <-chan int {
	output := make(chan int, len(values))
	enqueue(output, values)
	close(output)
	return output
}

func consume(input <-chan int) []int {
	var values []int
	for value := range input {
		values = append(values, value)
	}
	return values
}

func main() {
	values := consume(produce([]int{3, 5, 8}))
	fmt.Println("consumed:", values)
}
