package main

import "fmt"

func main() {
	shared := make([]int, 2, 3)
	shared[0], shared[1] = 10, 20
	fmt.Printf("spare capacity before append: %t\n", cap(shared) > len(shared))
	sharedAppended := append(shared, 30)
	fmt.Printf("shared append visible: %t\n", shared[:len(sharedAppended)][2] == 30)

	separate := make([]int, 2, 2)
	separate[0], separate[1] = 10, 20
	fmt.Printf("full capacity before append: %t\n", cap(separate) == len(separate))
	grown := append(separate, 30)
	grown[0] = 99
	fmt.Printf("old slice unchanged: %t\n", separate[0] == 10)
}
