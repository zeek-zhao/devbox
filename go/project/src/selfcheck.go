package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
)

func appRequest(handler http.Handler, method, path, body string) *httptest.ResponseRecorder {
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(method, path, strings.NewReader(body)))
	return response
}

func checkApplication(mode string) error {
	app, err := newAppBuilder().Pool(2, 4, 2, 0).Counting(mode).Build(slog.Default())
	if err != nil {
		return err
	}
	defer app.Shutdown()
	handler := app.HTTPHandler()
	response := appRequest(handler, "POST", "/submit", `{"id":1,"text":"Alpha alpha"}`)
	want := "{\"id\":1,\"status\":\"completed\",\"total\":2,\"words\":[{\"word\":\"alpha\",\"count\":2}]}\n"
	if mode == "exact" {
		want = "{\"id\":1,\"status\":\"completed\",\"total\":2,\"words\":[{\"word\":\"Alpha\",\"count\":1},{\"word\":\"alpha\",\"count\":1}]}\n"
	}
	if response.Code != http.StatusOK || response.Body.String() != want {
		return fmt.Errorf("application submit mismatch: status=%d body=%q", response.Code, response.Body.String())
	}
	metrics := appRequest(handler, "GET", "/processing-metrics", "")
	wantMetrics := "# HELP gateway_analysis_total Worker analysis outcomes.\n" +
		"# TYPE gateway_analysis_total counter\n" +
		"gateway_analysis_total{state=\"completed\"} 1\n" +
		"gateway_analysis_total{state=\"failed\"} 0\n"
	if metrics.Code != http.StatusOK || metrics.Body.String() != wantMetrics {
		return fmt.Errorf("application metrics mismatch: status=%d body=%q", metrics.Code, metrics.Body.String())
	}
	app.Shutdown()
	closed := appRequest(handler, "GET", "/healthz", "")
	if closed.Code != http.StatusServiceUnavailable {
		return fmt.Errorf("application shutdown health: %d", closed.Code)
	}
	return nil
}
