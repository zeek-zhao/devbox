package main

import (
	"bytes"
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"reflect"
	"strings"
	"sync"
	"testing"

	"devbox.local/gateway/internal/gateway"
)

func quietLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestApplicationPolicies(t *testing.T) {
	for _, mode := range []string{"folded", "exact"} {
		t.Run(mode, func(t *testing.T) {
			if err := checkApplication(mode); err != nil {
				t.Fatal(err)
			}
			app, err := newAppBuilder().Pool(2, 4, 2, 0).Counting(mode).Build(quietLogger())
			if err != nil {
				t.Fatal(err)
			}
			defer app.Shutdown()
			handler := app.HTTPHandler()
			response := appRequest(handler, "POST", "/submit", `{"id":7,"text":"世界 你好 世界"}`)
			want := "{\"id\":7,\"status\":\"completed\",\"total\":3,\"words\":[{\"word\":\"世界\",\"count\":2},{\"word\":\"你好\",\"count\":1}]}\n"
			if response.Code != http.StatusOK || response.Body.String() != want {
				t.Fatalf("Unicode result: %d %s", response.Code, response.Body.String())
			}
			invalid := appRequest(handler, "POST", "/submit", `{"id":0,"text":"bad"}`)
			if invalid.Code != http.StatusBadRequest {
				t.Fatalf("invalid task: %d", invalid.Code)
			}
			completed, failed := app.stats.snapshot()
			if completed != 1 || failed != 0 {
				t.Fatalf("rejected requests must not publish analysis outcomes: %d/%d", completed, failed)
			}
		})
	}
}

func TestBuilderValidationAndReuse(t *testing.T) {
	for _, builder := range []*appBuilder{
		newAppBuilder().Counting("unknown"),
		newAppBuilder().Pool(0, 1, 1, 0),
		newAppBuilder().Pool(1, 0, 1, 0),
		newAppBuilder().Pool(1, 1, 0, 0),
		newAppBuilder().Pool(1, 1, 1, -1),
	} {
		if app, err := builder.Build(quietLogger()); err == nil || app != nil {
			t.Fatalf("invalid builder: app=%v err=%v", app, err)
		}
	}
	if _, err := newAppBuilder().Build(nil); !errors.Is(err, gateway.ErrInvalid) {
		t.Fatalf("nil logger error: %v", err)
	}
	builder := newAppBuilder().Pool(1, 1, 1, 0)
	first, err := builder.Build(quietLogger())
	if err != nil {
		t.Fatal(err)
	}
	defer first.Shutdown()
	second, err := builder.Counting("exact").Build(quietLogger())
	if err != nil {
		t.Fatal(err)
	}
	defer second.Shutdown()
	for _, app := range []*application{first, second} {
		if _, err := app.gateway.Submit(context.Background(), gateway.Task{ID: 1, Text: "A a"}); err != nil {
			t.Fatal(err)
		}
	}
	if first.stats == second.stats {
		t.Fatal("builder instances share mutable statistics")
	}
}

type analysisFunc func(gateway.Task) (gateway.Result, error)

func (f analysisFunc) Analyze(task gateway.Task) (gateway.Result, error) { return f(task) }

func TestProcessingTemplate(t *testing.T) {
	task := gateway.Task{ID: 4, Text: "hello"}
	cause := errors.New("analysis failed")
	calls := 0
	step := analysisFunc(func(gateway.Task) (gateway.Result, error) {
		calls++
		return gateway.Result{}, cause
	})
	template := processingTemplate{step: step}
	if _, err := template.Process(gateway.Task{}); !errors.Is(err, gateway.ErrInvalid) || calls != 0 {
		t.Fatalf("validation must precede analysis: calls=%d err=%v", calls, err)
	}
	if _, err := template.Process(task); !errors.Is(err, cause) || calls != 1 {
		t.Fatalf("analysis error identity: calls=%d err=%v", calls, err)
	}
	for _, result := range []gateway.Result{
		{ID: 5, Total: 1, Words: []gateway.Word{{Text: "hello", Count: 1}}},
		{ID: 4, Total: 2, Words: []gateway.Word{{Text: "hello", Count: 1}}},
		{ID: 4},
		{ID: 4, Total: 1, Words: []gateway.Word{{Text: "", Count: 1}}},
		{ID: 4, Total: 1, Words: []gateway.Word{{Text: "hello", Count: 0}}},
		{ID: 4, Total: 2, Words: []gateway.Word{{Text: "z", Count: 1}, {Text: "a", Count: 1}}},
		{ID: 4, Total: 2, Words: []gateway.Word{{Text: "a", Count: 1}, {Text: "a", Count: 1}}},
	} {
		template.step = analysisFunc(func(gateway.Task) (gateway.Result, error) { return result, nil })
		if _, err := template.Process(task); !errors.Is(err, gateway.ErrInvalid) {
			t.Fatalf("invalid result accepted: %+v err=%v", result, err)
		}
	}
}

func TestAdapterPreservesCounterBehavior(t *testing.T) {
	for _, task := range []gateway.Task{{ID: 9, Text: "A a 世界"}, {ID: 0, Text: "bad"}} {
		want, wantErr := (&gateway.CounterProcessor{}).Process(task)
		got, gotErr := (&counterAdapter{}).Analyze(task)
		if !reflect.DeepEqual(got, want) || (gotErr == nil) != (wantErr == nil) {
			t.Fatalf("adapter differs: got=%+v/%v want=%+v/%v", got, gotErr, want, wantErr)
		}
		if wantErr != nil && !errors.Is(gotErr, gateway.ErrInvalid) {
			t.Fatalf("adapter lost error identity: %v", gotErr)
		}
	}
}

type processorFunc func(gateway.Task) (gateway.Result, error)

func (f processorFunc) Process(task gateway.Task) (gateway.Result, error) { return f(task) }

func TestDecoratorCompositeAndObservers(t *testing.T) {
	first, second := &processingStats{}, &processingStats{}
	var logs bytes.Buffer
	logger := slog.New(slog.NewTextHandler(&logs, nil))
	events := processingEvents{subscribers: observerGroup{
		first, observerGroup{second, failureObserver{logger: logger}},
	}}
	want := gateway.Result{ID: 3, Total: 1, Words: []gateway.Word{{Text: "ok", Count: 1}}}
	cause := errors.New("count failed")
	for _, err := range []error{nil, cause} {
		p := observedProcessor{next: processorFunc(func(gateway.Task) (gateway.Result, error) {
			return want, err
		}), events: events}
		got, gotErr := p.Process(gateway.Task{ID: 3, Text: "ok"})
		if !reflect.DeepEqual(got, want) || gotErr != err {
			t.Fatalf("decorator changed result/error: %+v %v", got, gotErr)
		}
	}
	if strings.Count(logs.String(), "task analysis failed") != 1 || !strings.Contains(logs.String(), cause.Error()) {
		t.Fatalf("failure observer output: %s", logs.String())
	}
	for _, stats := range []*processingStats{first, second} {
		if completed, failed := stats.snapshot(); completed != 1 || failed != 1 {
			t.Fatalf("nested composite notification: %d/%d", completed, failed)
		}
	}
}

func TestDecoratorPanicAndConcurrentWorkers(t *testing.T) {
	stats := &processingStats{}
	p := observedProcessor{
		next: processorFunc(func(task gateway.Task) (gateway.Result, error) {
			if task.Text == "panic" {
				panic(gateway.ErrInvalid)
			}
			return (&gateway.CounterProcessor{}).Process(task)
		}),
		events: processingEvents{subscribers: observerGroup{stats}},
	}
	g, err := gateway.New(gateway.Config{Workers: 4, Queue: 64, Burst: 64, Processor: p})
	if err != nil {
		t.Fatal(err)
	}
	defer g.Shutdown()
	if _, err := g.Submit(context.Background(), gateway.Task{ID: 1, Text: "panic"}); !errors.Is(err, gateway.ErrInvalid) {
		t.Fatalf("worker lost panic identity: %v", err)
	}
	var workers sync.WaitGroup
	for i := 0; i < 32; i++ {
		workers.Add(1)
		go func() {
			defer workers.Done()
			if _, err := g.Submit(context.Background(), gateway.Task{ID: 2, Text: "ok"}); err != nil {
				t.Error(err)
			}
		}()
	}
	workers.Wait()
	g.Shutdown()
	if completed, failed := stats.snapshot(); completed != 32 || failed != 1 {
		t.Fatalf("final analysis counts: %d/%d", completed, failed)
	}
}
