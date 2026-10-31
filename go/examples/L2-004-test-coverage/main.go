package main

func findValue(values map[string]string, key string) (string, bool) {
	if key == "" {
		return "", false
	}
	value, ok := values[key]
	if !ok {
		return "", false
	}
	return value, true
}

func main() {}
