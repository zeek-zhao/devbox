package main

import "fmt"

type Document struct {
	Title     string
	Pages     int
	Published bool
}

func main() {
	document := Document{Title: "Guide"}
	fmt.Printf("title: %s\n", document.Title)
	fmt.Printf("pages zero value: %d\n", document.Pages)
	fmt.Printf("published zero value: %t\n", document.Published)
}
