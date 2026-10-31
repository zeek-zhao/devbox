package lib

import "testing"

func TestNormalize(t *testing.T) {
	if got := Normalize("index"); got != "index" {
		t.Fatalf("Normalize() = %q, want %q", got, "index")
	}
}
