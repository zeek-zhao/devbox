package gateway

import (
	"context"
	"fmt"
	"reflect"
	"sync"
	"time"
)

type outcome struct {
	result Result
	err    error
}

type job struct {
	// L1-014-struct-embedding: embedding promotes the task fields in queued jobs.
	Task
	reply chan outcome
}

type Config struct {
	Workers   int
	Queue     int
	Burst     int
	Interval  time.Duration
	Processor Processor
}

type metrics struct {
	mu sync.Mutex
	// L1-008-arrays: a fixed-size array holds one counter per state.
	counts [stateCount]uint64
}

// L1-007-pointers: mutate shared counters through a pointer, under its mutex.
func (m *metrics) add(state State) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.counts[state]++
}

func (m *metrics) snapshot() [stateCount]uint64 {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.counts
}

type bucket struct {
	tokens chan struct{}
}

func (b *bucket) refill() {
	select {
	case b.tokens <- struct{}{}:
	default:
	}
}

// L1-015-method-receivers: pointer receiver consumes a shared token channel.
func (b *bucket) take() bool {
	select {
	case <-b.tokens:
		return true
	default:
		return false
	}
}

type Gateway struct {
	mu sync.Mutex
	// L1-002-zero-values: false, zero counters and WaitGroup start ready for use.
	closed     bool
	jobs       chan job
	workers    sync.WaitGroup
	stop       chan struct{}
	tickerDone chan struct{}
	processor  Processor
	bucket     bucket
	metrics    metrics
}

func New(c Config) (*Gateway, error) {
	if c.Workers < 1 || c.Workers > 1024 || c.Queue < 1 || c.Queue > 65536 || c.Burst < 1 || c.Burst > 65536 || c.Interval < 0 {
		return nil, fmt.Errorf("configuration: %w", ErrInvalid)
	}
	if c.Processor == nil {
		c.Processor = &CounterProcessor{}
	}
	// L1-018-nil-interfaces: an interface holding a typed nil pointer is not nil.
	v := reflect.ValueOf(c.Processor)
	switch v.Kind() {
	case reflect.Chan, reflect.Func, reflect.Interface, reflect.Map, reflect.Pointer, reflect.Slice:
		if v.IsNil() {
			return nil, fmt.Errorf("nil processor: %w", ErrInvalid)
		}
	}
	g := &Gateway{
		jobs: make(chan job, c.Queue), stop: make(chan struct{}), tickerDone: make(chan struct{}),
		processor: c.Processor, bucket: bucket{tokens: make(chan struct{}, c.Burst)},
	}
	for i := 0; i < c.Burst; i++ {
		g.bucket.refill()
	}
	g.workers.Add(c.Workers)
	for i := 0; i < c.Workers; i++ {
		// L1-027-goroutines: start exactly the configured number of workers.
		go g.worker(g.jobs)
	}
	if c.Interval == 0 {
		close(g.tickerDone)
	} else {
		go func() {
			defer close(g.tickerDone)
			ticker := time.NewTicker(c.Interval)
			defer ticker.Stop()
			for {
				select {
				case <-ticker.C:
					g.bucket.refill()
				case <-g.stop:
					return
				}
			}
		}()
	}
	return g, nil
}

// L1-021-defer-order-return: deferred recovery can change the named error result.
func execute(p Processor, t Task) (result Result, err error) {
	defer func() {
		// L1-022-panic-recover: isolate processor panics without losing the worker.
		if recovered := recover(); recovered != nil {
			// L1-017-type-assertions: preserve error identity for error-valued panics.
			if cause, ok := recovered.(error); ok {
				err = fmt.Errorf("processor panic: %w", cause)
			} else {
				err = fmt.Errorf("processor panic: %v", recovered)
			}
		}
	}()
	return p.Process(t)
}

// L1-029-directional-channels: workers may receive jobs but cannot enqueue or close.
func (g *Gateway) worker(jobs <-chan job) {
	defer g.workers.Done()
	// L1-026-range-semantics: each range iteration owns its job; close drains the queue.
	for j := range jobs {
		result, err := execute(g.processor, j.Task)
		if err != nil {
			g.metrics.add(Failed)
		} else {
			g.metrics.add(Completed)
		}
		j.reply <- outcome{result, err}
	}
}

func (g *Gateway) reject(err error) (Result, error) {
	g.metrics.add(Rejected)
	return Result{}, err
}

func (g *Gateway) Submit(ctx context.Context, task Task) (Result, error) {
	g.mu.Lock()
	if g.closed {
		g.mu.Unlock()
		return g.reject(ErrClosed)
	}
	if err := ctx.Err(); err != nil {
		g.mu.Unlock()
		return g.reject(err)
	}
	if err := Validate(task); err != nil {
		g.mu.Unlock()
		return g.reject(err)
	}
	if !g.bucket.take() {
		g.mu.Unlock()
		return g.reject(ErrLimited)
	}
	reply := make(chan outcome, 1)
	select {
	case g.jobs <- job{task, reply}:
		g.metrics.add(Accepted)
	default:
		g.bucket.refill()
		g.mu.Unlock()
		return g.reject(ErrFull)
	}
	g.mu.Unlock()
	// L1-028-channels-select-close: cancellation does not strand the buffered worker reply.
	select {
	case response := <-reply:
		return response.result, response.err
	case <-ctx.Done():
		return Result{}, ctx.Err()
	}
}

// L3-001-worker-pool-shutdown: serialize close against submit, then drain and join.
func (g *Gateway) Shutdown() {
	g.mu.Lock()
	if !g.closed {
		g.closed = true
		close(g.jobs)
		close(g.stop)
	}
	g.mu.Unlock()
	g.workers.Wait()
	<-g.tickerDone
}

func (g *Gateway) healthy() bool {
	g.mu.Lock()
	defer g.mu.Unlock()
	return !g.closed
}
