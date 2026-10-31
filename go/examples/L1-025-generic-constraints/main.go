package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"go/types"
)

type Integer interface {
	~int | ~int64
}

func sum[T Integer](values []T) T {
	var total T
	for _, value := range values {
		total += value
	}
	return total
}

func main() {
	fmt.Printf("sum int: %d\n", sum([]int{2, 3, 5}))
	fmt.Printf("sum int64: %d\n", sum([]int64{7, 11}))

	// Validate instantiation without putting an invalid call in the built program.
	const probe = `package probe
type Integer interface { ~int | ~int64 }
func sum[T Integer](values []T) T {
	var total T
	for _, value := range values { total += value }
	return total
}
`
	files := token.NewFileSet()
	source, err := parser.ParseFile(files, "probe.go", probe, 0)
	if err != nil {
		panic(err)
	}
	config := types.Config{}
	pkg, err := config.Check("probe", files, []*ast.File{source}, nil)
	if err != nil {
		panic(err)
	}
	signature := pkg.Scope().Lookup("sum").Type()
	_, constraintErr := types.Instantiate(nil, signature, []types.Type{types.Typ[types.String]}, true)
	fmt.Printf("string rejected by constraint: %t\n", constraintErr != nil)
}
