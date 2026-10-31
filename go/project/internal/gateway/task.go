// Package gateway implements bounded HTTP task execution.
package gateway

import (
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
	"unicode/utf8"
)

// L1-019-sentinel-errors: callers distinguish admission failures with errors.Is.
var ErrInvalid = errors.New("invalid task")
var ErrLimited = errors.New("rate limited")
var ErrFull = errors.New("queue full")
var ErrClosed = errors.New("gateway closed")

type State uint8

const (
	// L1-003-constants-iota: metric slots and job states have stable numeric identities.
	Accepted State = iota
	Completed
	Failed
	Rejected
	stateCount
)

// L1-013-structs: the HTTP input has explicit typed fields.
type Task struct { // L1-001-package-exports: Task is exported for main and external-package tests.
	// L1-032-json-tags: wire names are independent of exported Go field names.
	ID   uint32 `json:"id"`
	Text string `json:"text"`
}

type Word struct {
	Text  string `json:"word"`
	Count uint32 `json:"count"`
}

type Result struct {
	ID    uint32
	Total uint32
	Words []Word
}

// L3-004-custom-marshal-json: the public response has a stable, explicit wire shape.
func (r Result) MarshalJSON() ([]byte, error) {
	return json.Marshal(struct {
		ID     uint32 `json:"id"`
		Status string `json:"status"`
		Total  uint32 `json:"total"`
		Words  []Word `json:"words"`
	}{r.ID, "completed", r.Total, r.Words})
}

// L3-005-binary-format: versioned checkpoints encode fields, never struct memory.
func (r Result) MarshalBinary() ([]byte, error) {
	frame := make([]byte, 9)
	frame[0] = 1
	binary.BigEndian.PutUint32(frame[1:5], r.ID)
	binary.BigEndian.PutUint32(frame[5:9], r.Total)
	return frame, nil
}

func DecodeCheckpoint(frame []byte) (id, total uint32, err error) {
	if len(frame) != 9 || frame[0] != 1 {
		return 0, 0, fmt.Errorf("checkpoint: %w", ErrInvalid)
	}
	return binary.BigEndian.Uint32(frame[1:5]), binary.BigEndian.Uint32(frame[5:9]), nil
}

// L1-016-interfaces-method-sets: a pointer processor implicitly implements Processor.
type Processor interface {
	Process(Task) (Result, error)
}

var _ Processor = (*CounterProcessor)(nil)

type CounterProcessor struct{}

func Validate(t Task) error {
	if t.ID == 0 || !utf8.ValidString(t.Text) || strings.TrimSpace(t.Text) == "" || len(t.Text) > 4096 {
		return fmt.Errorf("id/text: %w", ErrInvalid)
	}
	return nil
}

// L1-025-generic-constraints: only ordered string-like keys can use this helper.
type textKey interface{ ~string }

// L1-024-generic-functions: generic key extraction also works for named string keys.
func sortedKeys[K textKey, V any](m map[K]V) []K {
	keys := make([]K, 0, len(m))
	for key := range m {
		keys = append(keys, key)
	}
	// L1-034-sorting-determinism: map iteration must not leak into HTTP output.
	sort.Slice(keys, func(i, j int) bool { return keys[i] < keys[j] })
	return keys
}

// L1-006-functions-results: processing returns both a value and an explicit failure.
func (*CounterProcessor) Process(t Task) (Result, error) {
	if err := Validate(t); err != nil {
		// L1-020-error-wrapping: preserve identity through the processing boundary.
		return Result{}, fmt.Errorf("process: %w", err)
	}
	counts := make(map[string]uint32)
	// L1-012-strings-runes: lowercasing and Fields handle Unicode, not ASCII byte offsets.
	fields := strings.Fields(strings.ToLower(t.Text))
	for _, field := range fields {
		// L1-011-maps-comma-ok: absent words are initialized before incrementing.
		count, exists := counts[field]
		if !exists {
			counts[field] = 1
		} else {
			counts[field] = count + 1
		}
	}
	// L1-010-slice-capacity: reserve the exact maximum number of distinct words.
	words := make([]Word, 0, len(counts))
	for _, key := range sortedKeys(counts) {
		words = append(words, Word{key, counts[key]})
	}
	// L1-035-integer-boundaries: reject overflow before narrowing a platform-sized int.
	if uint64(len(fields)) > math.MaxUint32 {
		return Result{}, fmt.Errorf("word count overflow: %w", ErrInvalid)
	}
	// L1-004-types-conversions: checked narrowing defines the wire integer width.
	return Result{ID: t.ID, Total: uint32(len(fields)), Words: words}, nil
}
