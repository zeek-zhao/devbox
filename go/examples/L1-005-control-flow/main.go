package main

import "fmt"

func describe(state string) string {
	switch state {
	case "ready":
		return "matched"
	default:
		return "default"
	}
}

func main() {
	score := 10
	if score >= 10 {
		fmt.Println("boundary: reached")
	} else {
		fmt.Println("boundary: not reached")
	}

	fmt.Printf("matching switch: %s\n", describe("ready"))
	fmt.Printf("default switch: %s\n", describe("unknown"))

	total := 0
	for step := 0; ; step++ {
		if step == 3 {
			break
		}
		total += step + 1
	}
	fmt.Printf("bounded loop total: %d\n", total)
}
