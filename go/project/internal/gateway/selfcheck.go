package gateway

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
)

const SelfCheckOutput = `health=200 ok
submit=200 {"id":1,"status":"completed","total":3,"words":[{"word":"alpha","count":2},{"word":"beta","count":1}]}
submit=200 {"id":2,"status":"completed","total":2,"words":[{"word":"世界","count":1},{"word":"你好","count":1}]}
limited=429
refilled=200 checkpoint=3/1
invalid=400
closed=503 health=503
# HELP gateway_tasks_total Tasks by lifecycle state.
# TYPE gateway_tasks_total counter
gateway_tasks_total{state="accepted"} 3
gateway_tasks_total{state="completed"} 3
gateway_tasks_total{state="failed"} 0
gateway_tasks_total{state="rejected"} 3
self-check OK
`

func request(handler http.Handler, method, path, body, accept string) *httptest.ResponseRecorder {
	r := httptest.NewRequest(method, path, strings.NewReader(body))
	r.Header.Set("Accept", accept)
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, r)
	return w
}

func SelfCheck(output io.Writer) error {
	g, err := New(Config{Workers: 2, Queue: 4, Burst: 2})
	if err != nil {
		return err
	}
	defer g.Shutdown()
	handler := g.HTTPHandler()
	var actual strings.Builder
	health := request(handler, "GET", "/healthz", "", "")
	fmt.Fprintf(&actual, "health=%d %s", health.Code, health.Body.String())
	for _, body := range []string{`{"id":1,"text":"Alpha beta alpha"}`, `{"id":2,"text":"你好 世界"}`} {
		w := request(handler, "POST", "/submit", body, "")
		fmt.Fprintf(&actual, "submit=%d %s", w.Code, w.Body.String())
	}
	limited := request(handler, "POST", "/submit", `{"id":3,"text":"refill"}`, "")
	fmt.Fprintf(&actual, "limited=%d\n", limited.Code)
	// The same refill operation as time.Ticker, driven explicitly instead of by wall time.
	g.bucket.refill()
	refilled := request(handler, "POST", "/submit", `{"id":3,"text":"refill"}`, "application/octet-stream")
	id, total, err := DecodeCheckpoint(refilled.Body.Bytes())
	if err != nil {
		return err
	}
	fmt.Fprintf(&actual, "refilled=%d checkpoint=%d/%d\n", refilled.Code, id, total)
	invalid := request(handler, "POST", "/submit", `{"id":0,"text":""}`, "")
	fmt.Fprintf(&actual, "invalid=%d\n", invalid.Code)
	g.Shutdown()
	closed := request(handler, "POST", "/submit", `{"id":4,"text":"closed"}`, "")
	health = request(handler, "GET", "/healthz", "", "")
	fmt.Fprintf(&actual, "closed=%d health=%d\n", closed.Code, health.Code)
	metrics := request(handler, "GET", "/metrics", "", "")
	if metrics.Code != http.StatusOK {
		return fmt.Errorf("metrics status: %d", metrics.Code)
	}
	actual.WriteString(metrics.Body.String())
	actual.WriteString("self-check OK\n")
	if actual.String() != SelfCheckOutput {
		return fmt.Errorf("self-check mismatch\nexpected:\n%sactual:\n%s", SelfCheckOutput, actual.String())
	}
	_, err = io.WriteString(output, actual.String())
	return err
}
