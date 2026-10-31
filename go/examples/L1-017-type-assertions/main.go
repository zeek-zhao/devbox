package main

import "fmt"

func main() {
	var input any = "query"
	value, ok := input.(string)
	fmt.Printf("string assertion: ok=%t value=%s\n", ok, value)

	number, ok := input.(int)
	fmt.Printf("int assertion: ok=%t value=%d\n", ok, number)
}
