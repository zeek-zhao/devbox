package main

import (
	"flag"
	"fmt"
	"os"
)

func run() int {
	name := flag.String("name", "", "name to display")
	flag.Parse()
	if *name == "" {
		fmt.Fprintln(os.Stderr, "name is required")
		flag.Usage()
		return 2
	}

	fmt.Printf("name: %s\n", *name)
	return 0
}

func main() {
	os.Exit(run())
}
