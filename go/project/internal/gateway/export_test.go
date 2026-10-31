package gateway_test

import (
	"context"
	"encoding/json"
	"testing"

	"devbox.local/gateway/internal/gateway"
)

// L2-011-package-tests: external-package tests use only the exported internal API.
func TestPublicAPI(t *testing.T) {
	g, err := gateway.New(gateway.Config{Workers: 1, Queue: 1, Burst: 1})
	if err != nil {
		t.Fatal(err)
	}
	defer g.Shutdown()
	result, err := g.Submit(context.Background(), gateway.Task{ID: 1, Text: "Beta alpha beta"})
	if err != nil {
		t.Fatal(err)
	}
	body, err := json.Marshal(result)
	if err != nil {
		t.Fatal(err)
	}
	want := `{"id":1,"status":"completed","total":3,"words":[{"word":"alpha","count":1},{"word":"beta","count":2}]}`
	if string(body) != want {
		t.Fatalf("wire result: %s", body)
	}
}
