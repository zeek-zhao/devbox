package main

import (
	"fmt"
	"sort"
)

func main() {
	documents := []int{10, 20}
	for i, value := range documents {
		value++
		fmt.Printf("slice index %d, changed copy: %d\n", i, value)
	}
	fmt.Printf("slice after value changes: %v\n", documents)
	for i := range documents {
		documents[i]++
	}
	fmt.Printf("slice after index changes: %v\n", documents)

	offsets := [2]int{4, 8}
	for i, value := range offsets {
		fmt.Printf("array index %d, value: %d\n", i, value)
	}
	for i, value := range "go" {
		fmt.Printf("string index %d, rune: %c\n", i, value)
	}
	counts := map[string]int{"query": 2, "index": 1}
	keys := make([]string, 0, len(counts))
	for key := range counts {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		fmt.Printf("map key %s, value: %d\n", key, counts[key])
	}
}
