package main

import "fmt"

type Handler interface {
	SetNext(Handler) Handler
	Handle(string) string
}

type LevelHandler struct {
	level string
	next  Handler
}

func (h *LevelHandler) SetNext(next Handler) Handler {
	h.next = next
	return next
}

func (h *LevelHandler) Handle(level string) string {
	if level == h.level {
		return "handled: " + h.level
	}
	if h.next != nil {
		return h.next.Handle(level)
	}
	return "handled: default"
}

func main() {
	var chain Handler = &LevelHandler{level: "info"}
	chain.SetNext(&LevelHandler{level: "warning"}).
		SetNext(&LevelHandler{level: "error"})
	for _, level := range []string{"info", "warning", "error", "unknown"} {
		fmt.Println(chain.Handle(level))
	}
}
