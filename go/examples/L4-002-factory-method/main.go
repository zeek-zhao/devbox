package main

import "fmt"

type Product interface {
	Name() string
}

type jsonParser struct{}
type textParser struct{}

func (jsonParser) Name() string { return "json parser" }
func (textParser) Name() string { return "text parser" }

func NewJSONParser() Product { return jsonParser{} }
func NewTextParser() Product { return textParser{} }

func PrintProduct(product Product) {
	fmt.Println(product.Name())
}

func main() {
	factories := []func() Product{NewJSONParser, NewTextParser}
	for _, create := range factories {
		PrintProduct(create())
	}
}
