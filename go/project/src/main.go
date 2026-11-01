package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"runtime/pprof"
	"syscall"
	"time"

	"devbox.local/gateway/internal/gateway"
)

func run() (err error) {
	// L2-008-flag-cli: flags select no-listener self-check or the real HTTP server.
	selfCheck := flag.Bool("self-check", false, "run deterministic in-memory HTTP checks")
	address := flag.String("addr", "127.0.0.1:8080", "HTTP listen address")
	workers := flag.Int("workers", 4, "worker count")
	queue := flag.Int("queue", 16, "queue capacity")
	burst := flag.Int("burst", 8, "token bucket capacity")
	interval := flag.Duration("refill", 100*time.Millisecond, "one token refill interval")
	wordMode := flag.String("word-mode", "folded", "word counting policy: folded or exact")
	profile := flag.String("cpu-profile", "", "write CPU profile to this file")
	flag.Parse()
	if flag.NArg() != 0 {
		return errors.New("unexpected positional arguments")
	}
	if *profile != "" {
		file, createErr := os.Create(*profile)
		if createErr != nil {
			return createErr
		}
		defer func() { err = errors.Join(err, file.Close()) }()
		// L3-003-cpu-profile: profile the actual gateway workload and flush on every exit.
		if err := pprof.StartCPUProfile(file); err != nil {
			return err
		}
		defer pprof.StopCPUProfile()
	}
	if *selfCheck {
		// L0-hello: anchor for validating the image and runner path.
		if err := checkApplication(*wordMode); err != nil {
			return err
		}
		return gateway.SelfCheck(os.Stdout)
	}
	if *interval <= 0 {
		return errors.New("refill must be positive in server mode")
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	// L2-009-slog-logging: operational errors go to stderr, not deterministic stdout.
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if a.Key == slog.TimeKey {
				return slog.Attr{}
			}
			return a
		},
	})))
	app, err := newAppBuilder().Pool(*workers, *queue, *burst, *interval).Counting(*wordMode).Build(slog.Default())
	if err != nil {
		return err
	}
	defer app.Shutdown()
	srv := &http.Server{Handler: app.HTTPHandler(), ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout: 10 * time.Second, WriteTimeout: 15 * time.Second, IdleTimeout: 30 * time.Second}
	listener, err := net.Listen("tcp", *address)
	if err != nil {
		return err
	}
	served := make(chan error, 1)
	go func() { served <- srv.Serve(listener) }()
	select {
	case err := <-served:
		if !errors.Is(err, http.ErrServerClosed) {
			return err
		}
		return nil
	case <-ctx.Done():
		shutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := srv.Shutdown(shutdown); err != nil {
			return errors.Join(err, srv.Close(), <-served)
		}
		if err := <-served; !errors.Is(err, http.ErrServerClosed) {
			return err
		}
		return nil
	}
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
