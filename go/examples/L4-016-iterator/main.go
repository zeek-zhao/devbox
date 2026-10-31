package main

import "fmt"

type Iterator interface {
	Next() (string, bool)
}

type Words struct{ items []string }

func (w Words) Iterator() Iterator {
	return &WordIterator{items: append([]string(nil), w.items...)}
}

type WordIterator struct {
	items []string
	index int
}

func (i *WordIterator) Next() (string, bool) {
	if i.index >= len(i.items) {
		return "", false
	}
	word := i.items[i.index]
	i.index++
	return word, true
}

func main() {
	words := Words{items: []string{"go", "design", "patterns"}}
	iterator := words.Iterator()
	for {
		word, ok := iterator.Next()
		if !ok {
			fmt.Printf("exhausted: %t\n", ok)
			break
		}
		fmt.Println("word:", word)
	}
	word, ok := iterator.Next()
	fmt.Printf("next again: %q %t\n", word, ok)
	independent := words.Iterator()
	word, ok = independent.Next()
	fmt.Printf("new iterator: %s %t\n", word, ok)
}
