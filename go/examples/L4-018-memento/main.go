package main

import "fmt"

type Memento struct {
	text string
	tags []string
}

type Editor struct {
	text string
	tags []string
}

func (e *Editor) Save() Memento {
	return Memento{text: e.text, tags: append([]string(nil), e.tags...)}
}

func (e *Editor) Restore(m Memento) {
	e.text = m.text
	e.tags = append([]string(nil), m.tags...)
}

func (e *Editor) Edit(text, tag string) {
	e.text = text
	e.tags[0] = tag
}

func (e *Editor) String() string {
	return fmt.Sprintf("text=%s tags=%v", e.text, e.tags)
}

type History struct{ snapshots []Memento }

func (h *History) Remember(e *Editor) { h.snapshots = append(h.snapshots, e.Save()) }

func (h *History) Restore(e *Editor, index int) {
	e.Restore(h.snapshots[index])
}

func main() {
	editor := &Editor{text: "draft", tags: []string{"original"}}
	history := &History{}
	history.Remember(editor)
	editor.Edit("published", "changed")
	fmt.Println("edited:", editor)
	history.Restore(editor, 0)
	fmt.Println("restored:", editor)
	editor.Edit("revised", "changed-again")
	history.Restore(editor, 0)
	fmt.Println("restored again:", editor)
}
