package main

import "fmt"

type Mediator interface {
	Broadcast(sender, message string)
}

type Colleague interface {
	Name() string
	Receive(string)
}

type Room struct{ colleagues []Colleague }

func (r *Room) Register(c Colleague) { r.colleagues = append(r.colleagues, c) }

func (r *Room) Broadcast(sender, message string) {
	for _, c := range r.colleagues {
		if c.Name() != sender {
			c.Receive(sender + ": " + message)
		}
	}
}

type Member struct {
	name     string
	mediator Mediator
	inbox    []string
}

func (m *Member) Name() string        { return m.name }
func (m *Member) Receive(text string) { m.inbox = append(m.inbox, text) }
func (m *Member) Send(message string) { m.mediator.Broadcast(m.name, message) }

func main() {
	room := &Room{}
	members := []*Member{
		{name: "alice", mediator: room},
		{name: "bob", mediator: room},
		{name: "carol", mediator: room},
	}
	for _, m := range members {
		room.Register(m)
	}
	for _, m := range members {
		m.Send("hello")
	}
	for _, m := range members {
		fmt.Printf("%s received: %d %v\n", m.name, len(m.inbox), m.inbox)
	}
}
