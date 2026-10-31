package main

import (
	"fmt"
	"strings"
)

type Query interface {
	Search(input string) string
}

type RealQuery struct {
	calls int
}

func (q *RealQuery) Search(input string) string {
	q.calls++
	return "found:" + strings.ToUpper(input)
}

type LoggingProxy struct {
	target Query
}

func NewLoggingProxy(target Query) Query {
	return &LoggingProxy{target: target}
}

func (p *LoggingProxy) Search(input string) string {
	fmt.Println("proxy: before")
	result := p.target.Search(input)
	fmt.Println("proxy: after")
	return result
}

func main() {
	real := &RealQuery{}
	var target Query = real
	direct := target.Search("go")
	proxy := NewLoggingProxy(target)
	result := proxy.Search("go")
	fmt.Printf("direct: %s\n", direct)
	fmt.Printf("proxied: %s\n", result)
	fmt.Printf("same result: %t\n", result == direct)
	fmt.Printf("target calls: %d\n", real.calls)
}
