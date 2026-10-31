package main

import "fmt"

type StoreError struct{}

func (*StoreError) Error() string {
	return "store error"
}

func main() {
	var storeError *StoreError
	var err error = storeError
	recovered, ok := err.(*StoreError)

	fmt.Printf("interface is nil: %t\n", err == nil)
	fmt.Printf("assertion succeeded: %t\n", ok)
	fmt.Printf("recovered pointer is nil: %t\n", recovered == nil)
}
