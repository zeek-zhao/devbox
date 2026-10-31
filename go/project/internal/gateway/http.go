package gateway

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"unicode/utf8"
)

func writeResponse(w http.ResponseWriter, status int, contentType string, body []byte) {
	w.Header().Set("Content-Type", contentType)
	w.WriteHeader(status)
	// L1-030-io-copy: stream the already-encoded body through Reader and Writer.
	if _, err := io.Copy(w, bytes.NewReader(body)); err != nil {
		slog.Error("response write failed", "error", err)
	}
}

func (g *Gateway) HTTPHandler() http.Handler {
	mux := http.NewServeMux()
	// L1-023-closures: handlers capture this gateway, not global process state.
	mux.HandleFunc("POST /submit", func(w http.ResponseWriter, r *http.Request) {
		defer r.Body.Close()
		raw, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 8192))
		if err != nil || !utf8.Valid(raw) {
			g.metrics.add(Rejected)
			writeResponse(w, http.StatusBadRequest, "text/plain; charset=utf-8", []byte("invalid JSON body\n"))
			return
		}
		decoder := json.NewDecoder(bytes.NewReader(raw))
		decoder.DisallowUnknownFields()
		var task Task
		if err := decoder.Decode(&task); err != nil {
			g.metrics.add(Rejected)
			writeResponse(w, http.StatusBadRequest, "text/plain; charset=utf-8", []byte("invalid JSON\n"))
			return
		}
		var extra any
		if err := decoder.Decode(&extra); err != io.EOF {
			g.metrics.add(Rejected)
			writeResponse(w, http.StatusBadRequest, "text/plain; charset=utf-8", []byte("expected one task\n"))
			return
		}
		result, err := g.Submit(r.Context(), task)
		if err != nil {
			status := http.StatusInternalServerError
			// L1-005-control-flow: errors determine explicit HTTP admission outcomes.
			switch {
			// L1-033-error-identity: wrapped validation failures retain HTTP 400 identity.
			case errors.Is(err, ErrInvalid):
				status = http.StatusBadRequest
			case errors.Is(err, ErrLimited):
				status = http.StatusTooManyRequests
			case errors.Is(err, ErrClosed), errors.Is(err, ErrFull):
				status = http.StatusServiceUnavailable
			case errors.Is(err, context.Canceled), errors.Is(err, context.DeadlineExceeded):
				status = http.StatusRequestTimeout
			}
			if status == http.StatusInternalServerError {
				slog.Error("task failed", "id", task.ID, "error", err)
			}
			writeResponse(w, status, "text/plain; charset=utf-8", []byte(http.StatusText(status)+"\n"))
			return
		}
		var body []byte
		contentType := "application/json"
		if r.Header.Get("Accept") == "application/octet-stream" {
			body, err = result.MarshalBinary()
			contentType = "application/octet-stream"
		} else {
			body, err = json.Marshal(result)
			body = append(body, '\n')
		}
		if err != nil {
			slog.Error("result encoding failed", "error", err)
			http.Error(w, "encoding failed", http.StatusInternalServerError)
			return
		}
		writeResponse(w, http.StatusOK, contentType, body)
	})
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		if !g.healthy() {
			writeResponse(w, http.StatusServiceUnavailable, "text/plain; charset=utf-8", []byte("draining\n"))
			return
		}
		writeResponse(w, http.StatusOK, "text/plain; charset=utf-8", []byte("ok\n"))
	})
	mux.HandleFunc("GET /metrics", func(w http.ResponseWriter, r *http.Request) {
		counts := g.metrics.snapshot()
		var body bytes.Buffer
		body.WriteString("# HELP gateway_tasks_total Tasks by lifecycle state.\n# TYPE gateway_tasks_total counter\n")
		for i, name := range [...]string{"accepted", "completed", "failed", "rejected"} {
			// L1-031-fmt-formatting: %q safely quotes labels; %d renders integer counters.
			fmt.Fprintf(&body, "gateway_tasks_total{state=%q} %d\n", name, counts[i])
		}
		writeResponse(w, http.StatusOK, "text/plain; version=0.0.4; charset=utf-8", body.Bytes())
	})
	return mux
}
