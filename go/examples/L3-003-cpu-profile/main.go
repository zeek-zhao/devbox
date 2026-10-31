package main

import (
	"os"
	"runtime"
	"runtime/pprof"
	"time"
)

//go:noinline
func profileWorkload(until time.Time) uint64 {
	var value uint64 = 1
	for time.Now().Before(until) {
		value = value*1664525 + 1013904223
	}
	runtime.KeepAlive(value)
	return value
}

func main() {
	profilePath := os.Getenv("PROFILE_PATH")
	file, err := os.Create(profilePath)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	if err := pprof.StartCPUProfile(file); err != nil {
		panic(err)
	}
	defer pprof.StopCPUProfile()

	profileWorkload(time.Now().Add(400 * time.Millisecond))
}
