package main

import (
	"errors"
	"fmt"
)

func validate(document string) error {
	if document == "" {
		return errors.New("empty document")
	}
	return nil
}

func taskBoundary(task func()) {
	defer func() {
		if reason := recover(); reason != nil {
			fmt.Printf("boundary recovered: %v\n", reason)
		}
	}()
	task()
	fmt.Println("task completed")
}

func main() {
	if err := validate(""); err != nil {
		fmt.Printf("ordinary error: %s\n", err)
	}
	taskBoundary(func() {
		panic("broken invariant")
	})
	fmt.Println("main continued after boundary")
	taskBoundary(func() {
		fmt.Println("next task: indexed")
	})
}
