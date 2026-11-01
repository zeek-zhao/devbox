package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"

	"devbox.local/gateway/internal/gateway"
)

// L4-021-strategy: counting policy changes without changing the worker or HTTP contract.
type analysis interface {
	Analyze(gateway.Task) (gateway.Result, error)
}

// L4-006-adapter: reuse the existing task processor behind the analysis-step interface.
type counterAdapter struct {
	counter gateway.CounterProcessor
}

func (a *counterAdapter) Analyze(task gateway.Task) (gateway.Result, error) {
	return a.counter.Process(task)
}

type exactAnalysis struct{}

func (exactAnalysis) Analyze(task gateway.Task) (gateway.Result, error) {
	fields := strings.Fields(task.Text)
	counts := make(map[string]uint32)
	for _, word := range fields {
		counts[word]++
	}
	words := make([]gateway.Word, 0, len(counts))
	for word, count := range counts {
		words = append(words, gateway.Word{Text: word, Count: count})
	}
	sort.Slice(words, func(i, j int) bool { return words[i].Text < words[j].Text })
	return gateway.Result{ID: task.ID, Total: uint32(len(fields)), Words: words}, nil
}

// L4-002-factory-method: each creator supplies the analysis step to the shared assembly.
type analysisFactory interface {
	NewAnalysis() analysis
}

type foldedFactory struct{}
type exactFactory struct{}

func (foldedFactory) NewAnalysis() analysis { return &counterAdapter{} }
func (exactFactory) NewAnalysis() analysis  { return exactAnalysis{} }

func countingFactory(mode string) (analysisFactory, error) {
	switch mode {
	case "folded":
		return foldedFactory{}, nil
	case "exact":
		return exactFactory{}, nil
	default:
		return nil, fmt.Errorf("word-mode must be folded or exact: %q", mode)
	}
}

type processingTemplate struct {
	step analysis
}

// L4-022-template-method: validation, variable analysis, then wire-invariant verification.
func (p processingTemplate) Process(task gateway.Task) (gateway.Result, error) {
	if err := gateway.Validate(task); err != nil {
		return gateway.Result{}, fmt.Errorf("process: %w", err)
	}
	result, err := p.step.Analyze(task)
	if err != nil {
		return gateway.Result{}, fmt.Errorf("analysis: %w", err)
	}
	var total uint64
	for i, word := range result.Words {
		if word.Text == "" || word.Count == 0 || (i > 0 && result.Words[i-1].Text >= word.Text) {
			return gateway.Result{}, fmt.Errorf("analysis returned invalid words: %w", gateway.ErrInvalid)
		}
		total += uint64(word.Count)
	}
	if result.ID != task.ID || total == 0 || total != uint64(result.Total) {
		return gateway.Result{}, fmt.Errorf("analysis returned invalid totals: %w", gateway.ErrInvalid)
	}
	return result, nil
}

type processingEvent struct {
	err error
}

type processingObserver interface {
	Observe(processingEvent)
}

// L4-008-composite: a group and a leaf obey the same notification interface.
type observerGroup []processingObserver

func (group observerGroup) Observe(event processingEvent) {
	for _, observer := range group {
		observer.Observe(event)
	}
}

// L4-019-observer: the publisher knows subscribers, not their metrics/logging behavior.
type processingEvents struct {
	subscribers observerGroup
}

func (events processingEvents) Publish(event processingEvent) {
	events.subscribers.Observe(event)
}

type processingStats struct {
	mu                sync.Mutex
	completed, failed uint64
}

func (s *processingStats) Observe(event processingEvent) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if event.err == nil {
		s.completed++
	} else {
		s.failed++
	}
}

func (s *processingStats) snapshot() (completed, failed uint64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.completed, s.failed
}

type failureObserver struct {
	logger *slog.Logger
}

func (o failureObserver) Observe(event processingEvent) {
	if event.err != nil {
		o.logger.Error("task analysis failed", "error", event.err)
	}
}

type observedProcessor struct {
	next   gateway.Processor
	events processingEvents
}

// L4-009-decorator: add completion notifications while preserving Processor results/errors.
func (p observedProcessor) Process(task gateway.Task) (result gateway.Result, err error) {
	defer func() {
		if value := recover(); value != nil {
			p.events.Publish(processingEvent{err: fmt.Errorf("analysis panic: %v", value)})
			panic(value) // The gateway worker retains responsibility for panic recovery.
		}
		p.events.Publish(processingEvent{err: err})
	}()
	return p.next.Process(task)
}

// L4-004-builder: collect pool and counting options before validating/starting workers.
type appBuilder struct {
	config gateway.Config
	mode   string
}

func newAppBuilder() *appBuilder {
	return &appBuilder{
		config: gateway.Config{Workers: 4, Queue: 16, Burst: 8, Interval: 100 * time.Millisecond},
		mode:   "folded",
	}
}

func (b *appBuilder) Pool(workers, queue, burst int, interval time.Duration) *appBuilder {
	b.config.Workers, b.config.Queue, b.config.Burst, b.config.Interval = workers, queue, burst, interval
	return b
}

func (b *appBuilder) Counting(mode string) *appBuilder {
	b.mode = mode
	return b
}

func (b *appBuilder) Build(logger *slog.Logger) (*application, error) {
	if logger == nil {
		return nil, fmt.Errorf("application logger: %w", gateway.ErrInvalid)
	}
	factory, err := countingFactory(b.mode)
	if err != nil {
		return nil, err
	}
	stats := &processingStats{}
	config := b.config
	config.Processor = observedProcessor{
		next: processingTemplate{step: factory.NewAnalysis()},
		events: processingEvents{subscribers: observerGroup{
			stats, failureObserver{logger: logger},
		}},
	}
	g, err := gateway.New(config)
	if err != nil {
		return nil, err
	}
	return &application{gateway: g, stats: stats}, nil
}

// L4-010-facade: callers manage one application, not the pool and observer subsystem separately.
type application struct {
	gateway *gateway.Gateway
	stats   *processingStats
}

func (a *application) HTTPHandler() http.Handler {
	mux := http.NewServeMux()
	mux.Handle("/", a.gateway.HTTPHandler())
	mux.HandleFunc("GET /processing-metrics", func(w http.ResponseWriter, r *http.Request) {
		completed, failed := a.stats.snapshot()
		w.Header().Set("Content-Type", "text/plain; version=0.0.4")
		if _, err := fmt.Fprintf(w, "# HELP gateway_analysis_total Worker analysis outcomes.\n"+
			"# TYPE gateway_analysis_total counter\n"+
			"gateway_analysis_total{state=\"completed\"} %d\n"+
			"gateway_analysis_total{state=\"failed\"} %d\n", completed, failed); err != nil {
			slog.Error("write processing metrics", "error", err)
		}
	})
	return mux
}

func (a *application) Shutdown() { a.gateway.Shutdown() }
