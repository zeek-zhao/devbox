package main

import "fmt"

func main() {
	original := [3]int{2, 4, 6}
	copyOfArray := original
	copyOfArray[0] = 99

	fmt.Printf("original: %v\n", original)
	fmt.Printf("copy: %v\n", copyOfArray)
	fmt.Printf("array length: %d\n", len(original))
}
