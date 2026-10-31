package main

import (
	"errors"
	"fmt"
)

type Request struct {
	Query string
	Limit int
}

type RequestBuilder struct {
	query string
	limit int
}

func (b *RequestBuilder) WithQuery(query string) *RequestBuilder {
	b.query = query
	return b
}

func (b *RequestBuilder) WithLimit(limit int) *RequestBuilder {
	b.limit = limit
	return b
}

func (b *RequestBuilder) Build() (Request, error) {
	if b.query == "" {
		return Request{}, errors.New("query is required")
	}
	if b.limit <= 0 {
		return Request{}, errors.New("limit must be positive")
	}
	return Request{Query: b.query, Limit: b.limit}, nil
}

func main() {
	builder := new(RequestBuilder).WithQuery("go").WithLimit(3)
	first, err := builder.Build()
	if err != nil {
		panic(err)
	}
	second, err := builder.WithLimit(5).Build()
	if err != nil {
		panic(err)
	}
	second.Query = "patterns"
	fmt.Printf("first: query=%s limit=%d\n", first.Query, first.Limit)
	fmt.Printf("second: query=%s limit=%d\n", second.Query, second.Limit)
	fmt.Printf("independent: %t\n", first.Query != second.Query && first.Limit != second.Limit)

	_, err = new(RequestBuilder).WithLimit(1).Build()
	fmt.Printf("missing query: %v\n", err)
}
