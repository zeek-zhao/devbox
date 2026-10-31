package main

import (
	"fmt"
	"io"
	"net"
	"time"
)

func main() {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		panic(err)
	}
	defer listener.Close()

	serverDone := make(chan error, 1)
	go func() {
		connection, acceptErr := listener.Accept()
		if acceptErr != nil {
			serverDone <- acceptErr
			return
		}
		defer connection.Close()
		if deadlineErr := connection.SetDeadline(time.Now().Add(2 * time.Second)); deadlineErr != nil {
			serverDone <- deadlineErr
			return
		}
		message := make([]byte, 4)
		if _, readErr := io.ReadFull(connection, message); readErr != nil {
			serverDone <- readErr
			return
		}
		_, writeErr := connection.Write(message)
		serverDone <- writeErr
	}()

	connection, err := net.DialTimeout("tcp", listener.Addr().String(), 2*time.Second)
	if err != nil {
		panic(err)
	}
	if err := connection.SetDeadline(time.Now().Add(2 * time.Second)); err != nil {
		panic(err)
	}
	message := []byte("PING")
	if _, err := connection.Write(message); err != nil {
		panic(err)
	}
	echo := make([]byte, len(message))
	if _, err := io.ReadFull(connection, echo); err != nil {
		panic(err)
	}
	if err := connection.Close(); err != nil {
		panic(err)
	}
	if err := <-serverDone; err != nil {
		panic(err)
	}
	if err := listener.Close(); err != nil {
		panic(err)
	}

	fmt.Printf("echo: %s\n", echo)
	fmt.Printf("server-exited: %t\n", true)
}
