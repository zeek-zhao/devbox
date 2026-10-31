package main

import (
	"fmt"
	"unicode/utf8"
)

func main() {
	text := "Go界"
	runes := []rune(text)
	fmt.Printf("byte length: %d\n", len(text))
	fmt.Printf("rune count: %d\n", utf8.RuneCountInString(text))
	fmt.Printf("first rune: %c\n", runes[0])
	fmt.Printf("first byte: %d\n", text[0])
}
