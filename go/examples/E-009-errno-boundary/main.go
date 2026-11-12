package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"strconv"
	"strings"
)

// 边界转换与错误码：标准库的错误约定是「包级 sentinel + 包装类型」
// （fs.ErrNotExist + *fs.PathError、*strconv.NumError）。在系统边界处
// 用 errors.Is/As 解码标准库错误，再映射成自己的稳定错误码（退出码）。

const (
	codeOK       = 0
	codeInvalid  = 2
	codeNotFound = 3
	codeUnknown  = 70
)

type stablePermissionError struct{}

func (stablePermissionError) Error() string { return "open config failed" }
func (stablePermissionError) Unwrap() error { return fs.ErrPermission }

func readConfig(path string) error {
	_, err := os.ReadFile(path)
	return err
}

func exitCodeFor(err error) int {
	var numErr *strconv.NumError
	switch {
	case err == nil:
		return codeOK
	case errors.Is(err, fs.ErrNotExist):
		return codeNotFound
	case errors.As(err, &numErr):
		return codeInvalid
	default:
		return codeUnknown
	}
}

func main() {
	// 1) 标准库错误沿约定带包装类型与底层原因
	err := readConfig("/tmp/devbox-e009-missing.conf")
	fmt.Printf("boundary text: %v\n", err)

	// 2) errors.As 取出 *fs.PathError 包装类型
	var pe *fs.PathError
	fmt.Printf("boundary is PathError: %t\n", errors.As(err, &pe))

	// 3) sentinel 解码 → 稳定错误码：文件不存在
	fmt.Printf("boundary code for missing file: %d\n", exitCodeFor(err))

	// 4) 解析类错误 → 另一个错误码
	_, perr := strconv.Atoi("not-a-number")
	fmt.Printf("boundary code for bad number: %d\n", exitCodeFor(perr))

	// 5) 成功与未知兜底
	fmt.Printf("boundary code for success: %d\n", exitCodeFor(nil))
	fmt.Printf("boundary code for unknown: %d\n", exitCodeFor(errors.New("mystery")))

	permissionErr := stablePermissionError{}
	badPermissionCheck := strings.Contains(permissionErr.Error(), "permission denied")
	goodPermissionCheck := errors.Is(permissionErr, fs.ErrPermission)
	fmt.Printf("antipattern=error-text-match bad=%t good=%t\n", badPermissionCheck, goodPermissionCheck)
}
