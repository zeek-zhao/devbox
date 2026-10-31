package main

import "testing"

func assertEqual(t *testing.T, got, want string) {
	t.Helper()
	if got != want {
		t.Fatalf("got %q, want %q", got, want)
	}
}

func TestLookup(t *testing.T) {
	records := map[string]string{"alpha": "first", "beta": "second"}
	tests := []struct {
		name string
		key  string
		want string
	}{
		{name: "first_record", key: "alpha", want: "first"},
		{name: "second_record", key: "beta", want: "second"},
		{name: "missing_record", key: "missing", want: ""},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			assertEqual(t, lookup(records, test.key), test.want)
		})
	}
}
