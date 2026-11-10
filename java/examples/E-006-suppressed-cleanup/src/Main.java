public class Main {
    static final class BusinessError extends RuntimeException {
        BusinessError(String message) {
            super(message);
        }
    }

    static final class FlakyClose implements AutoCloseable {
        @Override
        public void close() {
            throw new IllegalStateException("close failed");
        }
    }

    static void manualFinally() {
        try {
            throw new BusinessError("business failed");
        } finally {
            closeLikeLegacyCode();
        }
    }

    static void closeLikeLegacyCode() {
        throw new IllegalStateException("close failed");
    }

    public static void main(String[] args) {
        try {
            manualFinally();
        } catch (RuntimeException err) {
            System.out.println(
                    "manual-finally: surfaced="
                            + err.getClass().getSimpleName()
                            + " suppressed-count="
                            + err.getSuppressed().length
                            + " (business error masked by close failure)");
        }

        try (FlakyClose resource = new FlakyClose()) {
            throw new BusinessError("business failed");
        } catch (RuntimeException err) {
            int suppressed = err.getSuppressed().length;
            String suppressedType =
                    suppressed > 0 ? err.getSuppressed()[0].getClass().getSimpleName() : "none";
            System.out.println(
                    "twr: surfaced="
                            + err.getClass().getSimpleName()
                            + " suppressed=["
                            + suppressedType
                            + "]");
        }

        System.out.println("rule: cleanup failure must not mask the original error");
    }
}
