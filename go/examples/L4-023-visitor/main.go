package main

import "fmt"

type Element interface {
	Accept(Visitor)
}

type Visitor interface {
	VisitFile(*File)
	VisitFolder(*Folder)
}

type File struct {
	name string
	size int
}

func (f *File) Accept(v Visitor) { v.VisitFile(f) }

type Folder struct {
	name     string
	children int
}

func (f *Folder) Accept(v Visitor) { v.VisitFolder(f) }

type NameVisitor struct{}

func (NameVisitor) VisitFile(f *File)     { fmt.Println("name file:", f.name) }
func (NameVisitor) VisitFolder(f *Folder) { fmt.Println("name folder:", f.name) }

type MetricsVisitor struct{ totalBytes int }

func (v *MetricsVisitor) VisitFile(f *File) {
	v.totalBytes += f.size
	fmt.Printf("metrics file: %s bytes=%d\n", f.name, f.size)
}

func (v *MetricsVisitor) VisitFolder(f *Folder) {
	fmt.Printf("metrics folder: %s children=%d\n", f.name, f.children)
}

func main() {
	elements := []Element{
		&File{name: "main.go", size: 42},
		&Folder{name: "src", children: 1},
	}
	metrics := &MetricsVisitor{}
	for _, visitor := range []Visitor{NameVisitor{}, metrics} {
		for _, element := range elements {
			element.Accept(visitor)
		}
	}
	fmt.Printf("total bytes: %d\n", metrics.totalBytes)
}
