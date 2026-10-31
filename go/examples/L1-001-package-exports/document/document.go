package document

import "strings"

func Summary(title string) string {
	return normalize(title)
}

func normalize(title string) string {
	return strings.TrimSpace(title)
}
