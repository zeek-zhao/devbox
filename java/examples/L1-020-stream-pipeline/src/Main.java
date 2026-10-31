import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;

public class Main {
    public static void main(String[] args) {
        AtomicInteger processed = new AtomicInteger();
        Stream<Integer> pipeline = List.of(1, 2, 3, 4).stream()
                .filter(value -> value % 2 == 0)
                .map(value -> value * 2)
                .peek(value -> processed.incrementAndGet());

        System.out.println("processed before terminal=" + processed.get());
        List<Integer> values = pipeline.toList();
        System.out.println("values=" + values);
        System.out.println("processed after terminal=" + processed.get());

        boolean rejectedReuse = false;
        try {
            pipeline.count();
        } catch (IllegalStateException expected) {
            rejectedReuse = true;
        }
        System.out.println("rejects stream reuse=" + rejectedReuse);
    }
}
