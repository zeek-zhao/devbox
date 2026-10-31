package main

import (
	"errors"
	"fmt"
)

type Receiver interface {
	Add(int)
}

type Counter struct{ value int }

func (c *Counter) Add(delta int) { c.value += delta }

type Command interface {
	Execute()
	Undo()
}

type AddCommand struct {
	receiver Receiver
	delta    int
}

func (c AddCommand) Execute() { c.receiver.Add(c.delta) }
func (c AddCommand) Undo()    { c.receiver.Add(-c.delta) }

type Invoker struct {
	queue   []Command
	history []Command
}

func (i *Invoker) Enqueue(c Command) { i.queue = append(i.queue, c) }

func (i *Invoker) Execute() {
	for _, c := range i.queue {
		c.Execute()
		i.history = append(i.history, c)
	}
	i.queue = nil
}

func (i *Invoker) Undo() error {
	if len(i.history) == 0 {
		return errors.New("no command to undo")
	}
	last := len(i.history) - 1
	i.history[last].Undo()
	i.history = i.history[:last]
	return nil
}

func main() {
	counter := &Counter{}
	invoker := &Invoker{}
	invoker.Enqueue(AddCommand{receiver: counter, delta: 5})
	invoker.Enqueue(AddCommand{receiver: counter, delta: 3})
	invoker.Execute()
	fmt.Printf("after execute: %d\n", counter.value)
	if err := invoker.Undo(); err != nil {
		panic(err)
	}
	fmt.Printf("after undo: %d\n", counter.value)
}
