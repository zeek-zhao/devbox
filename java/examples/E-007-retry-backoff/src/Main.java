public class Main {
    static final class TransientException extends RuntimeException {
        TransientException(String message) {
            super(message);
        }
    }

    static final class ValidationException extends RuntimeException {
        ValidationException(String message) {
            super(message);
        }
    }

    static final class FlakyClient {
        private final int failTimes;
        private int calls;

        FlakyClient(int failTimes) {
            this.failTimes = failTimes;
        }

        String fetch(int attempt) {
            calls++;
            if (calls <= failTimes) {
                throw new TransientException("connect-refused");
            }
            return "payload-7";
        }
    }

    static String withRetry(ThrowingOp op, int retries, long baseMs) throws InterruptedException {
        StringBuilder delays = new StringBuilder();
        for (int attempt = 1; attempt <= retries; attempt++) {
            try {
                return op.run(attempt);
            } catch (TransientException err) {
                if (attempt == retries) {
                    throw err;
                }
                long delayMs = baseMs * (1L << (attempt - 1));
                if (delays.length() > 0) {
                    delays.append(',');
                }
                delays.append(delayMs);
                System.out.println("attempt " + attempt + " failed: TRANSIENT " + err.getMessage());
                Thread.sleep(delayMs);
            }
        }
        throw new IllegalStateException("unreachable");
    }

    interface ThrowingOp {
        String run(int attempt) throws InterruptedException;
    }

    static String badInput(int attempt) {
        throw new ValidationException("age must be a positive integer");
    }

    public static void main(String[] args) throws InterruptedException {
        String result = withRetry(new FlakyClient(2)::fetch, 3, 10);
        System.out.println("attempt 3 ok: got " + result);
        System.out.println("backoff: delays=10,20ms -> 2 retries before success");

        try {
            withRetry(Main::badInput, 3, 10);
        } catch (ValidationException err) {
            System.out.println(
                    "no-retry: "
                            + err.getClass().getSimpleName()
                            + " rejected immediately ("
                            + err.getMessage()
                            + ")");
        }
        System.out.println(
                "rule: retry only TRANSIENT errors, back off exponentially, cap the attempts");
    }
}
