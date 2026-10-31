package main

import "fmt"

type Steps interface {
	Prepare()
	Execute()
	Verify()
}

func RunWorkflow(steps Steps) {
	fmt.Println("begin")
	steps.Prepare()
	steps.Execute()
	steps.Verify()
	fmt.Println("end")
}

type Workflow struct{ steps Steps }

func (w Workflow) Run() { RunWorkflow(w.steps) }

type MemorySteps struct{ value int }

func (m *MemorySteps) Prepare() {
	m.value = 2
	fmt.Printf("memory prepare: %d\n", m.value)
}

func (m *MemorySteps) Execute() {
	m.value *= 3
	fmt.Printf("memory execute: %d\n", m.value)
}

func (m *MemorySteps) Verify() { fmt.Printf("memory verify: %t\n", m.value == 6) }

type TextSteps struct{ text string }

func (t *TextSteps) Prepare() {
	t.text = "go"
	fmt.Println("text prepare:", t.text)
}

func (t *TextSteps) Execute() {
	t.text += "-pattern"
	fmt.Println("text execute:", t.text)
}

func (t *TextSteps) Verify() { fmt.Printf("text verify: %t\n", t.text == "go-pattern") }

func main() {
	workflows := []Workflow{
		{steps: &MemorySteps{}},
		{steps: &TextSteps{}},
	}
	for _, workflow := range workflows {
		workflow.Run()
	}
}
