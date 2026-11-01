#include <float.h>
#include <math.h>
#include <stdio.h>

static int approximately_equal(double left, double right, double epsilon) {
    const double scale = fmax(fmax(fabs(left), fabs(right)), DBL_MIN);
    return fabs(left - right) <= epsilon * scale;
}

int main(void) {
    const double left = 0.1 + 0.2;
    const double right = 0.3;
    printf("exact_equal=%s\n", left == right ? "yes" : "no");
    printf("relative_equal=%s\n", approximately_equal(left, right, 1e-12) ? "yes" : "no");
    return 0;
}
