package main

import (
	"errors"
	"fmt"
)

type Glyph struct {
	symbol string
}

func (g *Glyph) Draw(x, y int) string {
	return fmt.Sprintf("%s at (%d,%d)", g.symbol, x, y)
}

type GlyphFactory struct {
	cache   map[string]*Glyph
	limit   int
	created int
}

func NewGlyphFactory(limit int) (*GlyphFactory, error) {
	if limit <= 0 {
		return nil, errors.New("cache limit must be positive")
	}
	return &GlyphFactory{cache: make(map[string]*Glyph), limit: limit}, nil
}

func (f *GlyphFactory) Get(symbol string) (*Glyph, error) {
	if symbol == "" {
		return nil, errors.New("symbol is required")
	}
	if glyph, ok := f.cache[symbol]; ok {
		return glyph, nil
	}
	if len(f.cache) >= f.limit {
		return nil, errors.New("glyph cache full")
	}
	glyph := &Glyph{symbol: symbol}
	f.cache[symbol] = glyph
	f.created++
	return glyph, nil
}

func main() {
	factory, err := NewGlyphFactory(2)
	if err != nil {
		panic(err)
	}
	first, err := factory.Get("A")
	if err != nil {
		panic(err)
	}
	second, err := factory.Get("A")
	if err != nil {
		panic(err)
	}
	other, err := factory.Get("B")
	if err != nil {
		panic(err)
	}
	fmt.Printf("same key pointer: %t\n", first == second)
	fmt.Printf("different key pointer: %t\n", first != other)
	fmt.Printf("created: %d\n", factory.created)
	fmt.Println(first.Draw(1, 2))
	fmt.Println(second.Draw(3, 4))
	_, err = factory.Get("C")
	fmt.Printf("new key at capacity: %v\n", err)
	cached, err := factory.Get("A")
	if err != nil {
		panic(err)
	}
	fmt.Printf("cached at capacity: %t\n", cached == first)
	fmt.Printf("created after capacity: %d\n", factory.created)
}
