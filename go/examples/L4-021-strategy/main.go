package main

import (
	"fmt"
	"sort"
)

type Strategy interface {
	Sort([]int) []int
}

type Ascending struct{}

func (Ascending) Sort(input []int) []int {
	result := append([]int(nil), input...)
	sort.Ints(result)
	return result
}

type Descending struct{}

func (Descending) Sort(input []int) []int {
	result := append([]int(nil), input...)
	sort.Sort(sort.Reverse(sort.IntSlice(result)))
	return result
}

type Sorter struct{ strategy Strategy }

func (s *Sorter) SetStrategy(strategy Strategy) { s.strategy = strategy }
func (s *Sorter) Sort(input []int) []int        { return s.strategy.Sort(input) }

func main() {
	input := []int{3, 1, 2}
	sorter := &Sorter{strategy: Ascending{}}
	fmt.Println("ascending:", sorter.Sort(input))
	sorter.SetStrategy(Descending{})
	fmt.Println("descending:", sorter.Sort(input))
	fmt.Println("input unchanged:", input)
}
