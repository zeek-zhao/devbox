package main

import "fmt"

type Node interface {
	Walk(indent string) []string
}

type File struct {
	name string
}

func (f File) Walk(indent string) []string {
	return []string{indent + "file:" + f.name}
}

type Directory struct {
	name     string
	children []Node
}

func (d Directory) Walk(indent string) []string {
	lines := []string{indent + "dir:" + d.name}
	for _, child := range d.children {
		lines = append(lines, child.Walk(indent+"  ")...)
	}
	return lines
}

func main() {
	var root Node = Directory{
		name: "root",
		children: []Node{
			File{name: "README"},
			Directory{
				name: "src",
				children: []Node{
					File{name: "main.go"},
					Directory{name: "empty"},
				},
			},
			File{name: "go.mod"},
		},
	}
	for _, line := range root.Walk("") {
		fmt.Println(line)
	}
}
