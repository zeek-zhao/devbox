package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
)

func main() {
	if len(os.Args) > 1 && os.Args[1] == "child" {
		fmt.Println("child-output")
		fmt.Fprintln(os.Stderr, "child-error")
		os.Exit(7)
	}

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd := exec.Command(os.Args[0], "child")
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()

	if stdout.String() != "child-output\n" {
		fmt.Fprintln(os.Stderr, "unexpected child stdout")
		os.Exit(1)
	}
	if stderr.String() != "child-error\n" {
		fmt.Fprintln(os.Stderr, "unexpected child stderr")
		os.Exit(1)
	}
	var exitErr *exec.ExitError
	if !errors.As(err, &exitErr) || exitErr.ExitCode() != 7 {
		fmt.Fprintln(os.Stderr, "unexpected child exit status")
		os.Exit(1)
	}

	fmt.Print("child stdout: ", stdout.String())
	fmt.Print("child stderr: ", stderr.String())
	fmt.Printf("child exit: %d\n", exitErr.ExitCode())
}
