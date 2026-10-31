package main

import (
	"fmt"

	"example.com/localparser"
)

func main() {
	fmt.Println("replace:", localparser.Parse("local-parser"))
}
