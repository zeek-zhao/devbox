package main

import "fmt"

func makeReaders() (func() int, func() int) {
	threshold := 3
	live := func() int {
		return threshold
	}
	snapshot := threshold
	fixed := func() int {
		return snapshot
	}
	threshold = 8
	return live, fixed
}

func main() {
	live, fixed := makeReaders()
	fmt.Printf("live after factory returned: %d\n", live())
	fmt.Printf("snapshot after factory returned: %d\n", fixed())
	fmt.Printf("live repeated: %d\n", live())
	fmt.Printf("snapshot repeated: %d\n", fixed())
}
