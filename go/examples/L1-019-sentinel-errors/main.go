package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("document not found")

func lookup(id int) (string, error) {
	if id != 7 {
		return "", ErrNotFound
	}
	return "guide", nil
}

func main() {
	document, err := lookup(7)
	fmt.Printf("found: %s, error-free: %t\n", document, err == nil)

	_, err = lookup(9)
	fmt.Printf("missing is sentinel: %t\n", errors.Is(err, ErrNotFound))
	if errors.Is(err, ErrNotFound) {
		fmt.Println("missing branch: no results")
	}
}
