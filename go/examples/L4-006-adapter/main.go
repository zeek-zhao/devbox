package main

import (
	"fmt"
	"strings"
)

type LegacyLookup struct {
	calls int
}

func (l *LegacyLookup) FindRecord(key string) string {
	l.calls++
	return "record:" + strings.ToUpper(key)
}

type Lookup interface {
	Lookup(key string) string
}

type LookupAdapter struct {
	*LegacyLookup
}

func (a LookupAdapter) Lookup(key string) string {
	return a.FindRecord(key)
}

var _ Lookup = LookupAdapter{}

func main() {
	legacy := &LegacyLookup{}
	direct := legacy.FindRecord("go")
	var lookup Lookup = LookupAdapter{LegacyLookup: legacy}
	adapted := lookup.Lookup("go")
	fmt.Printf("legacy: %s\n", direct)
	fmt.Printf("adapted: %s\n", adapted)
	fmt.Printf("same result: %t\n", direct == adapted)
	fmt.Printf("legacy calls: %d\n", legacy.calls)
}
