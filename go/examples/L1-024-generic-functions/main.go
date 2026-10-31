package main

import "fmt"

func reversed[T any](values []T) []T {
	result := make([]T, len(values))
	for i, value := range values {
		result[len(values)-1-i] = value
	}
	return result
}

func main() {
	numbers := []int{2, 4, 6}
	words := []string{"index", "query"}
	fmt.Printf("inferred int: %v\n", reversed(numbers))
	fmt.Printf("explicit string: %v\n", reversed[string](words))
	fmt.Printf("original int: %v\n", numbers)
	fmt.Printf("original string: %v\n", words)
	fmt.Printf("explicit empty int length: %d\n", len(reversed[int](nil)))
}
