package main

import (
	"fmt"
	"sort"
	"strings"
)

func sortedKeys(values map[string]int) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func main() {
	values := map[string]int{"gamma": 3, "alpha": 1, "beta": 2}
	first := sortedKeys(values)
	second := sortedKeys(values)

	fmt.Println("keys:", strings.Join(first, ","))
	fmt.Printf("repeated order matches: %t\n", strings.Join(first, ",") == strings.Join(second, ","))
	for _, key := range first {
		fmt.Printf("%s=%d\n", key, values[key])
	}
}
