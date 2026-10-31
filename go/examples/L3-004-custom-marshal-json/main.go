package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type Record struct {
	Name   string
	Active bool
}

func (record Record) MarshalJSON() ([]byte, error) {
	type recordAlias Record
	return json.Marshal(struct {
		Name   string `json:"name"`
		Active bool   `json:"active"`
	}{
		Name:   strings.ToUpper(record.Name),
		Active: recordAlias(record).Active,
	})
}

func main() {
	encoded, err := json.Marshal(Record{Name: "index", Active: true})
	if err != nil {
		panic(err)
	}
	var decoded struct {
		Name   string `json:"name"`
		Active bool   `json:"active"`
	}
	if err := json.Unmarshal(encoded, &decoded); err != nil {
		panic(err)
	}
	fmt.Printf("json: %s\n", encoded)
	fmt.Printf("round-trip: %t\n", decoded.Name == "INDEX" && decoded.Active)
}
