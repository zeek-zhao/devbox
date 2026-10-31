package main

import (
	"fmt"
	"strconv"
)

func parseCount(input string) (int, error) {
	value, err := strconv.Atoi(input)
	if err != nil {
		return 0, err
	}
	return value, nil
}

func main() {
	count, err := parseCount("42")
	if err != nil {
		fmt.Println("valid input failed")
		return
	}
	fmt.Printf("parsed count: %d\n", count)

	_, err = parseCount("not-a-number")
	if err != nil {
		fmt.Println("invalid input rejected: true")
		return
	}
	fmt.Println("invalid input rejected: false")
}
