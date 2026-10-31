package store

import "testing"

func TestKey(t *testing.T) {
	if got := Key("index"); got != "doc-index" {
		t.Fatalf("Key() = %q, want %q", got, "doc-index")
	}
}
