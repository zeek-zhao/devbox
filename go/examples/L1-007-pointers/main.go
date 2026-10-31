package main

import "fmt"

type Stats struct {
	Documents int
}

func incrementDocuments(stats *Stats) bool {
	if stats == nil {
		return false
	}
	stats.Documents++
	return true
}

func main() {
	stats := Stats{Documents: 4}
	incrementDocuments(&stats)
	fmt.Printf("documents after update: %d\n", stats.Documents)
	fmt.Printf("nil guarded: %t\n", !incrementDocuments(nil))
}
