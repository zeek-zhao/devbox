package main

import (
	"fmt"
	"sync"
)

type Observer interface {
	ID() string
	Update(string)
}

type Subject struct {
	mu        sync.Mutex
	state     string
	observers []Observer
}

func (s *Subject) Register(o Observer) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.observers = append(s.observers, o)
}

func (s *Subject) Unregister(id string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	remaining := make([]Observer, 0, len(s.observers))
	for _, o := range s.observers {
		if o.ID() != id {
			remaining = append(remaining, o)
		}
	}
	s.observers = remaining
}

func (s *Subject) SetState(state string) {
	s.mu.Lock()
	s.state = state
	snapshot := append([]Observer(nil), s.observers...)
	value := s.state
	s.mu.Unlock()
	// Snapshot semantics: registration changes affect the next notification.
	for _, o := range snapshot {
		o.Update(value)
	}
}

type Recorder struct {
	name     string
	messages []string
	onUpdate func()
}

func (r *Recorder) ID() string { return r.name }

func (r *Recorder) Update(value string) {
	r.messages = append(r.messages, value)
	fmt.Printf("%s observed: %s\n", r.name, value)
	if r.onUpdate != nil {
		r.onUpdate()
	}
}

func main() {
	subject := &Subject{}
	alice := &Recorder{name: "alice"}
	bob := &Recorder{name: "bob"}
	alice.onUpdate = func() { subject.Unregister(alice.ID()) }
	subject.Register(alice)
	subject.Register(bob)
	subject.SetState("ready")
	subject.SetState("done")
	fmt.Printf("notification counts: alice=%d bob=%d\n", len(alice.messages), len(bob.messages))
}
