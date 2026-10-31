package main

import (
	"fmt"
	"strings"
)

func main() {
	item := "index"
	count := 4
	message := fmt.Sprintf("item=%q count=%d", item, count)
	fmt.Println(message)
	fmt.Println("joined:", strings.Join([]string{"read", "parse", "write"}, " -> "))
}
