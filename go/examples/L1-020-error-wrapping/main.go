package main

import (
	"errors"
	"fmt"
)

var ErrUnreadable = errors.New("unreadable document")

type ReadError struct {
	Document string
	Cause    error
}

func (e *ReadError) Error() string {
	return fmt.Sprintf("read %s: %v", e.Document, e.Cause)
}

func (e *ReadError) Unwrap() error {
	return e.Cause
}

func main() {
	cause := &ReadError{Document: "guide.txt", Cause: ErrUnreadable}
	wrapped := fmt.Errorf("query: %w", cause)
	textOnly := fmt.Errorf("query: %v", cause)

	fmt.Printf("wrapped text: %s\n", wrapped)
	fmt.Printf("wrapped is sentinel: %t\n", errors.Is(wrapped, ErrUnreadable))
	var detail *ReadError
	matched := errors.As(wrapped, &detail)
	fmt.Printf("wrapped as ReadError: %t\n", matched)
	if matched {
		fmt.Printf("document: %s\n", detail.Document)
	}
	fmt.Printf("text-only is sentinel: %t\n", errors.Is(textOnly, ErrUnreadable))
	var lost *ReadError
	fmt.Printf("text-only as ReadError: %t\n", errors.As(textOnly, &lost))
}
