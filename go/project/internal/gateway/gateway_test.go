package gateway

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"
)

func newTestGateway(t *testing.T, config Config) *Gateway {
	t.Helper()
	g, err := New(config)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(g.Shutdown)
	return g
}

func TestSelfCheck(t *testing.T) {
	var output bytes.Buffer
	if err := SelfCheck(&output); err != nil {
		t.Fatal(err)
	}
	if output.String() != SelfCheckOutput {
		t.Fatal(output.String())
	}
}

// L2-003-table-tests: valid, boundary and malformed input share a named table.
func TestValidation(t *testing.T) {
	for _, tc := range []struct {
		name  string
		task  Task
		valid bool
	}{
		{"valid", Task{1, "a"}, true},
		{"max id", Task{^uint32(0), "a"}, true},
		{"max text", Task{1, strings.Repeat("a", 4096)}, true},
		{"zero id", Task{0, "a"}, false},
		{"blank", Task{1, " \t\n"}, false},
		{"too long", Task{1, strings.Repeat("a", 4097)}, false},
		{"invalid utf8", Task{1, string([]byte{0xff})}, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			err := Validate(tc.task)
			if (err == nil) != tc.valid || (!tc.valid && !errors.Is(err, ErrInvalid)) {
				t.Fatalf("validation: %v", err)
			}
		})
	}
}

func TestHTTPInput(t *testing.T) {
	g := newTestGateway(t, Config{Workers: 1, Queue: 1, Burst: 32})
	for _, body := range []string{
		`{`, `null`, `[]`, `{"id":-1,"text":"a"}`, `{"id":4294967296,"text":"a"}`,
		`{"id":1,"text":"a","unknown":true}`, `{"id":1,"text":"a"} {}`,
		`{"id":1,"text":"` + strings.Repeat("a", 8192) + `"}`,
		"{\"id\":1,\"text\":\"\xff\"}",
	} {
		if w := request(g.HTTPHandler(), "POST", "/submit", body, ""); w.Code != http.StatusBadRequest {
			t.Fatalf("status %d for invalid input", w.Code)
		}
	}
	if w := request(g.HTTPHandler(), "GET", "/submit", "", ""); w.Code != http.StatusMethodNotAllowed {
		t.Fatalf("method status: %d", w.Code)
	}
}

type processorFunc func(Task) (Result, error)

func (f processorFunc) Process(t Task) (Result, error) { return f(t) }

func TestPanicIsolation(t *testing.T) {
	cause := errors.New("plugin failure")
	g := newTestGateway(t, Config{Workers: 1, Queue: 2, Burst: 3, Processor: processorFunc(func(task Task) (Result, error) {
		if task.ID == 1 {
			panic(cause)
		}
		if task.ID == 2 {
			panic("non-error panic")
		}
		return (&CounterProcessor{}).Process(task)
	})})
	if _, err := g.Submit(context.Background(), Task{1, "a"}); !errors.Is(err, cause) {
		t.Fatalf("panic identity: %v", err)
	}
	if _, err := g.Submit(context.Background(), Task{2, "a"}); err == nil || !strings.Contains(err.Error(), "non-error panic") {
		t.Fatalf("panic diagnostic: %v", err)
	}
	if result, err := g.Submit(context.Background(), Task{3, "still working"}); err != nil || result.Total != 2 {
		t.Fatalf("worker after panic: %v %v", result, err)
	}
	if counts := g.metrics.snapshot(); counts[Failed] != 2 || counts[Completed] != 1 {
		t.Fatal(counts)
	}
}

func TestTypedNil(t *testing.T) {
	var processor *CounterProcessor
	if _, err := New(Config{Workers: 1, Queue: 1, Burst: 1, Processor: processor}); !errors.Is(err, ErrInvalid) {
		t.Fatalf("typed nil: %v", err)
	}
}

func TestSliceOwnership(t *testing.T) {
	original := []Word{{"alpha", 1}, {"beta", 2}}
	// L1-009-slice-backing-array: a full slice expression forces append to detach a checkpoint view.
	view := original[:1:1]
	appended := append(view, Word{"gamma", 3})
	appended[0].Count = 9
	if original[0].Count != 1 || original[1].Text != "beta" {
		t.Fatal("append must detach before mutating the result")
	}
	shared := original[:1]
	shared = append(shared, Word{"delta", 4})
	if original[1].Text != "delta" {
		t.Fatal("append within capacity must share the result backing array")
	}
}

func TestCheckpoint(t *testing.T) {
	frame, err := (Result{ID: 0x01020304, Total: 5}).MarshalBinary()
	if err != nil || !bytes.Equal(frame, []byte{1, 1, 2, 3, 4, 0, 0, 0, 5}) {
		t.Fatalf("frame: %v %v", frame, err)
	}
	id, total, err := DecodeCheckpoint(frame)
	if err != nil || id != 0x01020304 || total != 5 {
		t.Fatalf("decode: %d %d %v", id, total, err)
	}
	for n := 0; n < len(frame); n++ {
		if _, _, err := DecodeCheckpoint(frame[:n]); !errors.Is(err, ErrInvalid) {
			t.Fatalf("accepted truncated frame of length %d", n)
		}
	}
	frame[0] = 2
	if _, _, err := DecodeCheckpoint(frame); !errors.Is(err, ErrInvalid) {
		t.Fatal("accepted unknown version")
	}
}

func TestTickerRefill(t *testing.T) {
	g := newTestGateway(t, Config{Workers: 1, Queue: 1, Burst: 1, Interval: time.Millisecond})
	if !g.bucket.take() {
		t.Fatal("bucket must start full")
	}
	select {
	case <-g.bucket.tokens:
	case <-time.After(2 * time.Second):
		t.Fatal("ticker did not refill")
	}
	for i := 0; i < 5; i++ {
		g.bucket.refill()
	}
	if len(g.bucket.tokens) > 1 {
		t.Fatal("bucket exceeded capacity")
	}
}

func TestQueueDrainAndCancellation(t *testing.T) {
	started := make(chan struct{})
	release := make(chan struct{})
	var once sync.Once
	g := newTestGateway(t, Config{Workers: 1, Queue: 1, Burst: 4, Processor: processorFunc(func(task Task) (Result, error) {
		once.Do(func() { close(started) })
		<-release
		return (&CounterProcessor{}).Process(task)
	})})
	defer close(release)
	first, cancel := context.WithCancel(context.Background())
	firstDone := make(chan error, 1)
	go func() { _, err := g.Submit(first, Task{1, "a"}); firstDone <- err }()
	<-started
	cancel()
	if err := <-firstDone; !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
	second, cancelSecond := context.WithCancel(context.Background())
	secondDone := make(chan error, 1)
	go func() { _, err := g.Submit(second, Task{2, "b"}); secondDone <- err }()
	deadline := time.NewTimer(2 * time.Second)
	defer deadline.Stop()
	for g.metrics.snapshot()[Accepted] != 2 {
		select {
		case <-deadline.C:
			t.Fatal("second job was not queued")
		default:
			time.Sleep(time.Millisecond)
		}
	}
	if _, err := g.Submit(context.Background(), Task{3, "c"}); !errors.Is(err, ErrFull) {
		t.Fatalf("full queue: %v", err)
	}
	cancelSecond()
	if err := <-secondDone; !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
	// Cleanup releases the processor before Shutdown; accepted jobs must still finish.
	t.Cleanup(func() {
		if counts := g.metrics.snapshot(); counts[Accepted] != counts[Completed] {
			t.Fatalf("lost accepted jobs: %v", counts)
		}
	})
	// Cleanup is LIFO: join before asserting counts, after the deferred release.
	t.Cleanup(g.Shutdown)
}

func TestConcurrentShutdown(t *testing.T) {
	g := newTestGateway(t, Config{Workers: 4, Queue: 128, Burst: 128})
	var wg sync.WaitGroup
	for i := 1; i <= 100; i++ {
		wg.Add(1)
		go func(id uint32) {
			defer wg.Done()
			_, err := g.Submit(context.Background(), Task{id, "parallel task"})
			if err != nil && !errors.Is(err, ErrClosed) {
				t.Errorf("submit: %v", err)
			}
		}(uint32(i))
	}
	wg.Add(2)
	for i := 0; i < 2; i++ {
		go func() { defer wg.Done(); g.Shutdown() }()
	}
	wg.Wait()
	if counts := g.metrics.snapshot(); counts[Accepted] != counts[Completed] || counts[Accepted]+counts[Rejected] != 100 {
		t.Fatal(counts)
	}
}

func TestLocalReplacement(t *testing.T) {
	manifest, err := os.ReadFile("../../go.mod")
	if err != nil {
		t.Fatal(err)
	}
	// A temporary consumer activates the local replace without changing the zero-require project.
	probe := filepath.Join(t.TempDir(), "probe.mod")
	if err := os.WriteFile(probe, append(manifest, []byte("\nrequire devbox.local/gateway-checkout v0.0.0\n")...), 0600); err != nil {
		t.Fatal(err)
	}
	// L2-001-local-module-replace: resolve the checkout through replace, never a remote dependency.
	command := exec.Command("go", "list", "-modfile="+probe, "-m", "-f", "{{.Dir}}", "devbox.local/gateway-checkout")
	command.Dir = "../.."
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("local module replacement: %v\n%s", err, output)
	}
	expected, err := filepath.Abs("../..")
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(output)) != expected {
		t.Fatalf("replacement directory: %q", output)
	}
}

func TestExitFixture(t *testing.T) {
	if os.Getenv("GATEWAY_FAIL_TEST") == "1" {
		t.Fatal("intentional gateway test failure")
	}
}

func TestExitStatus(t *testing.T) {
	// L2-010-os-exec: invoke the tool with separate arguments and inspect its exit error.
	command := exec.Command("go", "test", "-count=1", "-run", "^TestExitFixture$", ".")
	command.Env = append(os.Environ(), "GATEWAY_FAIL_TEST=1")
	output, err := command.CombinedOutput()
	var exit *exec.ExitError
	// L2-012-test-exit-status: a deliberately failing test must make the Go runner nonzero.
	if !errors.As(err, &exit) || exit.ExitCode() != 1 || !bytes.Contains(output, []byte("intentional gateway test failure")) {
		t.Fatalf("failure exit was not propagated: %v\n%s", err, output)
	}
}

// L2-005-go-benchmark: measure the real Unicode counting and deterministic sorting path.
func BenchmarkProcess(b *testing.B) {
	p := &CounterProcessor{}
	task := Task{1, strings.Repeat("alpha beta 你好 世界 alpha ", 64)}
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		if _, err := p.Process(task); err != nil {
			b.Fatal(err)
		}
	}
}
