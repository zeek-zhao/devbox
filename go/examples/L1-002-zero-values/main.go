package main

import "fmt"

type Settings struct {
	Limit   int
	Enabled bool
}

func main() {
	shortDeclared := 7
	var number int
	var enabled bool
	var label string
	var pointer *int
	var values []int
	var counts map[string]int
	var settings Settings

	fmt.Printf("short declaration: %d\n", shortDeclared)
	fmt.Printf("int zero: %d\n", number)
	fmt.Printf("bool zero: %t\n", enabled)
	fmt.Printf("string zero: %q\n", label)
	fmt.Printf("pointer is nil: %t\n", pointer == nil)
	fmt.Printf("slice is nil: %t\n", values == nil)
	fmt.Printf("map is nil: %t\n", counts == nil)
	fmt.Printf("struct zero: %+v\n", settings)

	counts = make(map[string]int)
	counts["ready"] = 1
	fmt.Printf("initialized map value: %d\n", counts["ready"])
}
