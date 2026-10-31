package main

import "fmt"

type Renderer interface {
	Render(text string) string
}

type PlainRenderer struct{}
type HTMLRenderer struct{}

func (PlainRenderer) Render(text string) string { return "plain:" + text }
func (HTMLRenderer) Render(text string) string  { return "<p>" + text + "</p>" }

type Message interface {
	Display(text string) string
}

type Notice struct {
	renderer Renderer
}

func (n Notice) Display(text string) string {
	return n.renderer.Render("notice:" + text)
}

type Alert struct {
	renderer Renderer
}

func (a Alert) Display(text string) string {
	return a.renderer.Render("alert:" + text)
}

func main() {
	messages := []Message{
		Notice{renderer: PlainRenderer{}},
		Notice{renderer: HTMLRenderer{}},
		Alert{renderer: PlainRenderer{}},
		Alert{renderer: HTMLRenderer{}},
	}
	for _, message := range messages {
		fmt.Println(message.Display("go"))
	}
}
