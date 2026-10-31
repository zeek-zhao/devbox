package failing

import "testing"

func TestIntentionalFailure(t *testing.T) {
	t.Fatal("intentional failure for exit-status demonstration")
}
