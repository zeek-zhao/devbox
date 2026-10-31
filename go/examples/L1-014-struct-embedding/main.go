package main

import "fmt"

type Stats struct {
	label string
}

func (s Stats) Label() string {
	return s.label
}

type Index struct {
	Stats
	name string
}

func (i Index) Label() string {
	return i.name
}

func main() {
	index := Index{Stats: Stats{label: "stats"}, name: "index"}
	fmt.Printf("promoted field method: %s\n", index.Stats.Label())
	fmt.Printf("outer method: %s\n", index.Label())
}
