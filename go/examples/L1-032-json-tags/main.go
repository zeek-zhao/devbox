package main

import (
	"encoding/json"
	"fmt"
)

type record struct {
	Name   string `json:"name"`
	Count  int    `json:"count"`
	Note   string `json:"note,omitempty"`
	hidden string
}

func main() {
	original := record{Name: "Ada", Count: 3, hidden: "not encoded"}
	encoded, err := json.Marshal(original)
	if err != nil {
		panic(err)
	}

	var decoded record
	if err := json.Unmarshal(encoded, &decoded); err != nil {
		panic(err)
	}
	if decoded.Name != original.Name || decoded.Count != original.Count || decoded.hidden != "" {
		panic("decoded fields do not match the JSON contract")
	}

	fmt.Printf("json: %s\n", encoded)
	fmt.Printf("round trip: name=%s count=%d hidden-empty=%t\n",
		decoded.Name, decoded.Count, decoded.hidden == "")
}
