package store

import (
	"example.com/package-tests/internal/token"
	"example.com/package-tests/lib"
)

func Key(value string) string {
	return token.Prefix + lib.Normalize(value)
}
