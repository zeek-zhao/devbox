package main

import "fmt"

func fitsInt8(value int64) bool {
	const minInt8 int64 = -1 << 7
	const maxInt8 int64 = 1<<7 - 1
	return value >= minInt8 && value <= maxInt8
}

func main() {
	fmt.Printf("int8 minimum accepted: %t\n", fitsInt8(-128))
	fmt.Printf("int8 maximum accepted: %t\n", fitsInt8(127))
	fmt.Printf("int8 overflow rejected: %t\n", !fitsInt8(128))

	candidate := int64(127)
	converted := int8(0)
	if fitsInt8(candidate) {
		converted = int8(candidate)
	}
	fmt.Printf("checked conversion: %d\n", converted)

	left, right := uint64(5), uint64(3)
	if left < right {
		panic("unsigned subtraction would underflow")
	}
	fmt.Printf("safe unsigned difference: %d\n", left-right)

	lower, upper := uint64(3), uint64(5)
	fmt.Printf("underflow rejected before subtraction: %t\n", lower < upper)
}
