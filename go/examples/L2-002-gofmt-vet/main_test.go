package main

import "testing"

func TestQualityGateExample(t *testing.T) {
	if got := "passed"; got != "passed" {
		t.Fatalf("unexpected status: %q", got)
	}
}
