package main

import "fmt"

type State int

const (
	stateNew State = iota + 1
	stateIndexed
	stateReady
)

const (
	firstInNewGroup = iota
	secondInNewGroup
)

func main() {
	fmt.Printf("states: %d %d %d\n", stateNew, stateIndexed, stateReady)
	fmt.Printf("new group: %d %d\n", firstInNewGroup, secondInNewGroup)
}
