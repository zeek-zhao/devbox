package main

import "fmt"

type Text interface {
	Content() string
}

type PlainText string

func (t PlainText) Content() string { return string(t) }

type Brackets struct {
	inner Text
}

func (b Brackets) Content() string { return "[" + b.inner.Content() + "]" }

func WithBrackets(inner Text) Text { return Brackets{inner: inner} }

type Prefix struct {
	inner Text
	label string
}

func (p Prefix) Content() string { return p.label + p.inner.Content() }

func WithPrefix(inner Text, label string) Text {
	return Prefix{inner: inner, label: label}
}

func main() {
	var base Text = PlainText("go")
	decorated := WithPrefix(WithBrackets(base), "cached:")
	fmt.Printf("base: %s\n", base.Content())
	fmt.Printf("two layers: %s\n", decorated.Content())
	fmt.Printf("reversed: %s\n", WithBrackets(WithPrefix(base, "cached:")).Content())
}
