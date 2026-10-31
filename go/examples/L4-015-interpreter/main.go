package main

import "fmt"

type Expression interface {
	Interpret() int
}

type Number int

func (n Number) Interpret() int { return int(n) }

type Add struct{ left, right Expression }

func (a Add) Interpret() int { return a.left.Interpret() + a.right.Interpret() }

type Multiply struct{ left, right Expression }

func (m Multiply) Interpret() int { return m.left.Interpret() * m.right.Interpret() }

func main() {
	var expression Expression = Multiply{
		left:  Add{left: Number(2), right: Number(3)},
		right: Number(4),
	}
	fmt.Printf("(2 + 3) * 4 = %d\n", expression.Interpret())
}
