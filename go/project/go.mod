module devbox.local/gateway

go 1.23

// The test's temporary consumer activates this local-only replacement.
replace devbox.local/gateway-checkout => .
