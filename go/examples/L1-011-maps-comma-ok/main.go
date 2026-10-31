package main

import (
	"fmt"
	"sort"
)

func main() {
	counts := map[string]int{"zero": 0, "pear": 2, "apple": 1}

	value, ok := counts["missing"]
	fmt.Printf("missing: value=%d ok=%t\n", value, ok)
	value, ok = counts["zero"]
	fmt.Printf("zero: value=%d ok=%t\n", value, ok)

	delete(counts, "pear")
	_, ok = counts["pear"]
	fmt.Printf("pear after delete: ok=%t\n", ok)

	keys := make([]string, 0, len(counts))
	for key := range counts {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		fmt.Printf("%s=%d\n", key, counts[key])
	}
}
