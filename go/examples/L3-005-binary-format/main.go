package main

import (
	"encoding/binary"
	"errors"
	"fmt"
)

const formatVersion byte = 1
const recordSize = 7

type Record struct {
	ID    uint32
	Count uint16
}

func encode(record Record) []byte {
	data := make([]byte, recordSize)
	data[0] = formatVersion
	binary.BigEndian.PutUint32(data[1:5], record.ID)
	binary.BigEndian.PutUint16(data[5:7], record.Count)
	return data
}

func decode(data []byte) (Record, error) {
	if len(data) != recordSize {
		return Record{}, errors.New("invalid record length")
	}
	if data[0] != formatVersion {
		return Record{}, errors.New("unsupported format version")
	}
	return Record{
		ID:    binary.BigEndian.Uint32(data[1:5]),
		Count: binary.BigEndian.Uint16(data[5:7]),
	}, nil
}

func main() {
	want := Record{ID: 0x01020304, Count: 7}
	data := encode(want)
	got, err := decode(data)
	if err != nil {
		panic(err)
	}
	_, truncatedErr := decode(data[:len(data)-1])
	fmt.Printf("bytes: % x\n", data)
	fmt.Printf("round-trip: %t\n", got == want)
	fmt.Printf("truncated-rejected: %t\n", truncatedErr != nil)
}
