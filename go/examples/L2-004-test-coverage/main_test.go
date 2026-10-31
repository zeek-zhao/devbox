package main

import "testing"

func TestFindValue(t *testing.T) {
	values := map[string]string{"alpha": "first"}
	got, ok := findValue(values, "alpha")
	if !ok || got != "first" {
		t.Fatalf("findValue() = (%q, %t), want (%q, true)", got, ok, "first")
	}
}
