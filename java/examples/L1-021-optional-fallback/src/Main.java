import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;

public class Main {
    private static String defaultValue(AtomicInteger calls) {
        calls.incrementAndGet();
        return "missing";
    }

    public static void main(String[] args) {
        Optional<String> present = Optional.of("guide");
        Optional<String> absent = Optional.empty();
        AtomicInteger eagerCalls = new AtomicInteger();
        AtomicInteger lazyCalls = new AtomicInteger();

        System.out.println("mapped=" + present.map(String::toUpperCase).orElseGet(() -> "missing"));
        System.out.println("fallback=" + absent.flatMap(value -> Optional.of(value + "!"))
                .orElseGet(() -> "missing"));
        System.out.println("orElse-eager-calls="
                + present.orElse(defaultValue(eagerCalls)) + ":" + eagerCalls.get());
        System.out.println("orElseGet-calls="
                + present.orElseGet(() -> defaultValue(lazyCalls)) + ":" + lazyCalls.get());
        try {
            absent.get();
        } catch (java.util.NoSuchElementException exception) {
            System.out.println("empty-get=" + exception.getClass().getSimpleName());
        }
    }
}
