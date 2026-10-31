package main

import "testing"

func BenchmarkTokenize(b *testing.B) {
	input := "local index search uses stable tokens"
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = tokenize(input)
	}
}
