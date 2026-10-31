package main

import "fmt"

type Shape interface {
	Clone() Shape
	SetLabel(index int, label string)
	Labels() []string
}

type Diagram struct {
	labels []string
}

func (d *Diagram) Clone() Shape {
	return &Diagram{labels: append([]string(nil), d.labels...)}
}

func (d *Diagram) SetLabel(index int, label string) {
	d.labels[index] = label
}

func (d *Diagram) Labels() []string {
	return append([]string(nil), d.labels...)
}

func main() {
	var original Shape = &Diagram{labels: []string{"circle", "square"}}
	copy := original.Clone()
	copy.SetLabel(0, "triangle")
	fmt.Printf("same instance: %t\n", original == copy)
	fmt.Printf("original: %v\n", original.Labels())
	fmt.Printf("clone: %v\n", copy.Labels())
	original.SetLabel(1, "star")
	fmt.Printf("clone after original edit: %v\n", copy.Labels())
}
