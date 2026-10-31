//go:build integration

// L2-006-build-tags: real TCP tests are opt-in; default/self-check never open a port.
package gateway

import (
	"bytes"
	"context"
	"io"
	"net"
	"net/http"
	"testing"
	"time"
)

func TestTCPCheckpointEcho(t *testing.T) {
	// L3-006-tcp-echo: round-trip the gateway checkpoint over a real loopback TCP echo connection.
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	done := make(chan error, 1)
	go func() {
		conn, err := listener.Accept()
		if err != nil {
			done <- err
			return
		}
		defer conn.Close()
		if err := conn.SetDeadline(time.Now().Add(2 * time.Second)); err != nil {
			done <- err
			return
		}
		_, err = io.Copy(conn, conn)
		done <- err
	}()
	conn, err := net.DialTimeout("tcp", listener.Addr().String(), 2*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	if err := conn.SetDeadline(time.Now().Add(2 * time.Second)); err != nil {
		t.Fatal(err)
	}
	g := newTestGateway(t, Config{Workers: 1, Queue: 1, Burst: 1})
	result, err := g.Submit(context.Background(), Task{1, "tcp checkpoint"})
	if err != nil {
		t.Fatal(err)
	}
	frame, err := result.MarshalBinary()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := io.Copy(conn, bytes.NewReader(frame)); err != nil {
		t.Fatal(err)
	}
	reply := make([]byte, len(frame))
	if _, err := io.ReadFull(conn, reply); err != nil || !bytes.Equal(reply, frame) {
		t.Fatalf("echo: %x %v", reply, err)
	}
	if err := conn.Close(); err != nil {
		t.Fatal(err)
	}
	if err := <-done; err != nil {
		t.Fatal(err)
	}
}

func TestTCPHealth(t *testing.T) {
	g := newTestGateway(t, Config{Workers: 1, Queue: 1, Burst: 1})
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	server := &http.Server{Handler: g.HTTPHandler(), ReadHeaderTimeout: time.Second}
	done := make(chan error, 1)
	go func() { done <- server.Serve(listener) }()
	t.Cleanup(func() {
		if err := server.Close(); err != nil {
			t.Error(err)
		}
		if err := <-done; err != http.ErrServerClosed {
			t.Error(err)
		}
	})
	client := &http.Client{Timeout: 2 * time.Second}
	response, err := client.Get("http://" + listener.Addr().String() + "/healthz")
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil || response.StatusCode != http.StatusOK || string(body) != "ok\n" {
		t.Fatalf("TCP response: %d %q %v", response.StatusCode, body, err)
	}
	client.CloseIdleConnections()
}
