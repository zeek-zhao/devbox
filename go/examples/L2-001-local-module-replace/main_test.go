package main

import (
	"testing"

	"example.com/localparser"
)

func TestLocalModuleReplace(t *testing.T) {
	if got := localparser.Parse("local-parser"); got != "local-parser" {
		t.Fatalf("Parse() = %q, want %q", got, "local-parser")
	}
}
