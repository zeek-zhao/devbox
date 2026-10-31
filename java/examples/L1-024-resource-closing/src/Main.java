import java.util.ArrayList;
import java.util.List;

public class Main {
    private static final class TestResource implements AutoCloseable {
        private final String name;
        private final List<String> closed;
        private final boolean failOnClose;

        private TestResource(String name, List<String> closed, boolean failOnClose) {
            this.name = name;
            this.closed = closed;
            this.failOnClose = failOnClose;
        }

        @Override
        public void close() {
            closed.add(name);
            if (failOnClose) {
                throw new IllegalStateException(name + "-close");
            }
        }
    }

    private static String joined(List<String> values) {
        return String.join(",", values);
    }

    public static void main(String[] args) {
        List<String> normalCloseOrder = new ArrayList<>();
        try (TestResource first = new TestResource("first", normalCloseOrder, false);
             TestResource second = new TestResource("second", normalCloseOrder, false)) {
            System.out.println("body=completed");
        }
        System.out.println("normal-close-order=" + joined(normalCloseOrder));

        List<String> failingCloseOrder = new ArrayList<>();
        try (TestResource first = new TestResource("first", failingCloseOrder, true);
             TestResource second = new TestResource("second", failingCloseOrder, true)) {
            throw new IllegalArgumentException("body-failure");
        } catch (IllegalArgumentException exception) {
            System.out.println("primary=" + exception.getMessage());
            System.out.println("suppressed="
                    + exception.getSuppressed()[0].getMessage() + ","
                    + exception.getSuppressed()[1].getMessage());
            System.out.println("failure-close-order=" + joined(failingCloseOrder));
        }
    }
}
