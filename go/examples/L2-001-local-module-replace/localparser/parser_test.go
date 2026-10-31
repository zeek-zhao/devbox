package localparser

import "testing"

func TestParse(t *testing.T) {
	if got := Parse("value"); got != "value" {
		t.Fatalf("Parse() = %q, want %q", got, "value")
	}
}
