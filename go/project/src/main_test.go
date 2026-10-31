package main

import (
	"flag"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"devbox.local/gateway/internal/gateway"
)

func cli(t *testing.T, args ...string) error {
	t.Helper()
	previousFlags, previousArgs := flag.CommandLine, os.Args
	flag.CommandLine = flag.NewFlagSet("gateway-test", flag.ContinueOnError)
	os.Args = append([]string{"gateway-test"}, args...)
	defer func() {
		flag.CommandLine, os.Args = previousFlags, previousArgs
	}()
	return run()
}

func TestCLIValidation(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want string
	}{
		{"arguments", []string{"unexpected"}, "unexpected positional"},
		{"refill", []string{"--refill=0"}, "refill must be positive"},
		{"workers", []string{"--workers=0"}, "configuration"},
		{"queue", []string{"--queue=-1"}, "configuration"},
		{"burst", []string{"--burst=0"}, "configuration"},
		{"profile path", []string{"--cpu-profile=" + filepath.Join(t.TempDir(), "absent", "cpu.pprof")}, "no such file"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if err := cli(t, tc.args...); err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("CLI error: %v", err)
			}
		})
	}
}

func TestCLISelfCheckProfile(t *testing.T) {
	dir := t.TempDir()
	output, err := os.Create(filepath.Join(dir, "stdout"))
	if err != nil {
		t.Fatal(err)
	}
	previous := os.Stdout
	os.Stdout = output
	defer func() {
		os.Stdout = previous
		if err := output.Close(); err != nil {
			t.Error(err)
		}
	}()
	profile := filepath.Join(dir, "cpu.pprof")
	if err := cli(t, "--self-check", "--cpu-profile="+profile); err != nil {
		t.Fatal(err)
	}
	body, err := os.ReadFile(output.Name())
	if err != nil || string(body) != gateway.SelfCheckOutput {
		t.Fatalf("self-check stdout: %s %v", body, err)
	}
	data, err := os.ReadFile(profile)
	if err != nil || len(data) < 2 || data[0] != 0x1f || data[1] != 0x8b {
		t.Fatalf("profile was not flushed to gzip: %v", err)
	}
}
