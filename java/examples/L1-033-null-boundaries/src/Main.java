import java.util.Objects;

public final class Main {
    private static String label(String value) {
        return value.toLowerCase();
    }

    public static void main(String[] args) {
        try {
            label(null);
            throw new IllegalStateException("null dereference was not rejected");
        } catch (NullPointerException expected) {
            System.out.println("direct-call=null-rejected");
        }

        System.out.println("equals-null=" + Objects.equals(null, null));
        System.out.println("equals-value=" + Objects.equals(null, "value"));

        try {
            Objects.requireNonNull(null, "value is required");
            throw new IllegalStateException("required null was accepted");
        } catch (NullPointerException expected) {
            if (!"value is required".equals(expected.getMessage())) {
                throw new IllegalStateException("unexpected null message", expected);
            }
            System.out.println("required-null=value is required");
        }
    }
}
