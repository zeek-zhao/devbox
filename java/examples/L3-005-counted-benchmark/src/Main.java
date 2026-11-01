public class Main {
    private static final int SAMPLES = 5;

    public static void main(String[] args) {
        int[] values = new int[1000];
        for (int index = 0; index < values.length; index++) {
            values[index] = index;
        }

        long warmupChecksum = 0;
        for (int index = 0; index < 100; index++) {
            warmupChecksum += linear(values, 999).value();
            warmupChecksum += binary(values, 999).value();
        }
        if (warmupChecksum == 0) {
            throw new IllegalStateException("warmup result was not consumed");
        }

        long checksum = 0;
        int linearChecks = 0;
        int binaryChecks = 0;
        long[] elapsedSamples = new long[SAMPLES];
        for (int sample = 0; sample < SAMPLES; sample++) {
            long started = System.nanoTime();
            SearchResult linear = linear(values, 999);
            SearchResult binary = binary(values, 999);
            elapsedSamples[sample] = System.nanoTime() - started;
            if (linear.value() != binary.value()) {
                throw new IllegalStateException("algorithms disagree");
            }
            checksum += linear.value() + binary.value();
            linearChecks = linear.checks();
            binaryChecks = binary.checks();
        }
        for (long elapsed : elapsedSamples) {
            System.err.println("elapsed-nanos=" + elapsed);
        }

        if (linearChecks != 1000 || binaryChecks > 10 || checksum != 9990) {
            throw new IllegalStateException("operation-count validation failed");
        }
        System.out.println("linear-checks: " + linearChecks);
        System.out.println("binary-checks: " + binaryChecks);
        System.out.println("checksum: " + checksum);
    }

    private static SearchResult linear(int[] values, int target) {
        int checks = 0;
        for (int value : values) {
            checks++;
            if (value == target) {
                return new SearchResult(value, checks);
            }
        }
        return new SearchResult(-1, checks);
    }

    private static SearchResult binary(int[] values, int target) {
        int low = 0;
        int high = values.length - 1;
        int checks = 0;
        while (low <= high) {
            int middle = low + (high - low) / 2;
            checks++;
            if (values[middle] == target) {
                return new SearchResult(values[middle], checks);
            }
            if (values[middle] < target) {
                low = middle + 1;
            } else {
                high = middle - 1;
            }
        }
        return new SearchResult(-1, checks);
    }

    private record SearchResult(int value, int checks) {}
}
