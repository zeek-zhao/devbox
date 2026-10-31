package main

import "fmt"

type State interface {
	Handle(*Context) State
}

type Context struct {
	state State
	work  int
}

func (c *Context) Request() { c.state = c.state.Handle(c) }

type Pending struct{ next State }

func (s Pending) Handle(c *Context) State {
	c.work++
	fmt.Printf("pending: started work=%d\n", c.work)
	return s.next
}

type Running struct{ next State }

func (s Running) Handle(c *Context) State {
	c.work++
	fmt.Printf("running: finished work=%d\n", c.work)
	return s.next
}

type Done struct{}

func (s Done) Handle(c *Context) State {
	fmt.Printf("done: unchanged work=%d\n", c.work)
	return s
}

func main() {
	done := Done{}
	running := Running{next: done}
	ctx := &Context{state: Pending{next: running}}
	ctx.Request()
	ctx.Request()
	ctx.Request()
}
