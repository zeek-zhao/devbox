package main

import (
	"fmt"
	"strings"
)

type parser struct{}

func (parser) parse(input string) []string {
	words := strings.Fields(input)
	fmt.Printf("parse: %v\n", words)
	return words
}

type indexer struct{}

func (indexer) index(words []string) string {
	key := strings.ToUpper(strings.Join(words, "+"))
	fmt.Printf("index: %s\n", key)
	return key
}

type renderer struct{}

func (renderer) render(key string) string {
	result := "result[" + key + "]"
	fmt.Printf("render: %s\n", result)
	return result
}

type SearchFacade struct {
	parser   parser
	indexer  indexer
	renderer renderer
}

func NewSearchFacade() *SearchFacade {
	return &SearchFacade{parser: parser{}, indexer: indexer{}, renderer: renderer{}}
}

func (f *SearchFacade) Search(input string) string {
	words := f.parser.parse(input)
	key := f.indexer.index(words)
	return f.renderer.render(key)
}

func main() {
	search := NewSearchFacade()
	fmt.Printf("facade: %s\n", search.Search("  go patterns  "))
}
