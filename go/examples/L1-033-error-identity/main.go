package main

import (
	"errors"
	"fmt"
)

func main() {
	first := errors.New("record missing")
	second := errors.New("record missing")
	sentinel := errors.New("record missing")
	wrapped := fmt.Errorf("lookup failed: %w", sentinel)

	fmt.Printf("same text: %t\n", first.Error() == second.Error())
	fmt.Printf("same error value: %t\n", first == second)
	fmt.Printf("sentinel recognized: %t\n", errors.Is(wrapped, sentinel))
}
