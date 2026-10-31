package main

import "fmt"

func main() {
	shared := []string{"first", "tail"}
	short := shared[:1]
	short = append(short, "added")
	fmt.Printf("two-index append overwrote tail: %s\n", shared[1])

	isolated := []string{"first", "tail"}
	bounded := isolated[:1:1]
	bounded = append(bounded, "added")
	fmt.Printf("full-slice append preserved tail: %s\n", isolated[1])
	fmt.Printf("appended value: %s\n", bounded[1])
}
