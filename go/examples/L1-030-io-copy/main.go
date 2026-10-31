package main

import (
	"bytes"
	"fmt"
	"io"
	"strings"
)

func main() {
	const input = "import-ready"
	reader := strings.NewReader(input)
	var output bytes.Buffer

	copied, err := io.Copy(&output, reader)
	if err != nil {
		panic(err)
	}
	if copied != int64(len(input)) {
		panic("unexpected copied byte count")
	}

	fmt.Printf("copied bytes: %d\n", copied)
	fmt.Printf("content: %s\n", output.String())
}
