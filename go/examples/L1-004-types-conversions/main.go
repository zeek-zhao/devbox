package main

import "fmt"

func checkedByte(value int32) (byte, bool) {
	if value < 0 || value > 255 {
		return 0, false
	}
	return byte(value), true
}

func main() {
	wideValue := int32(255)
	converted, inRange := checkedByte(wideValue)
	fmt.Printf("converted boundary: %d\n", converted)
	fmt.Printf("boundary accepted: %t\n", inRange)

	_, stillInRange := checkedByte(256)
	fmt.Printf("out of range rejected: %t\n", !stillInRange)
}
