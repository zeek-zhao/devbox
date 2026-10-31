package main

import (
	"fmt"
	"reflect"
)

type Saver interface {
	Save()
}

type Record struct{}

func (*Record) Save() {}

var _ Saver = (*Record)(nil)

func main() {
	saverType := reflect.TypeOf((*Saver)(nil)).Elem()
	fmt.Printf("Record implements Saver: %t\n", reflect.TypeOf(Record{}).Implements(saverType))
	fmt.Printf("*Record implements Saver: %t\n", reflect.TypeOf((*Record)(nil)).Implements(saverType))
}
