package main

import "fmt"

type Counter struct {
	value int
}

func (c Counter) Snapshot() int {
	c.value++
	return c.value
}

func (c *Counter) Increment() {
	c.value++
}

func main() {
	counter := Counter{value: 4}
	fmt.Printf("value receiver result: %d\n", counter.Snapshot())
	fmt.Printf("after value receiver: %d\n", counter.value)
	counter.Increment()
	fmt.Printf("after pointer receiver: %d\n", counter.value)
}
