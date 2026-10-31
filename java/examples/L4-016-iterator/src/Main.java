import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;

public class Main {
    static final class Sequence<T> implements Iterable<T> {
        private final List<T> elements;

        Sequence(List<T> elements) {
            this.elements = List.copyOf(elements);
        }

        @Override public Iterator<T> iterator() {
            return new Cursor();
        }

        private final class Cursor implements Iterator<T> {
            private int position;

            @Override public boolean hasNext() {
                return position < elements.size();
            }

            @Override public T next() {
                if (!hasNext()) {
                    throw new NoSuchElementException("Sequence exhausted");
                }
                return elements.get(position++);
            }
        }
    }

    public static void main(String[] args) {
        Sequence<String> sequence = new Sequence<>(List.of("alpha", "beta", "gamma"));
        Iterator<String> cursor = sequence.iterator();
        List<String> visited = new ArrayList<>();
        while (cursor.hasNext()) {
            if (!cursor.hasNext()) {
                throw new IllegalStateException("hasNext advanced the cursor");
            }
            visited.add(cursor.next());
        }
        System.out.println("visited: " + String.join(", ", visited));
        System.out.println("hasNext: " + cursor.hasNext());
        try {
            cursor.next();
            throw new IllegalStateException("Exhausted iterator returned an element");
        } catch (NoSuchElementException expected) {
            System.out.println("exhausted: " + expected.getClass().getSimpleName());
        }
        System.out.println("fresh cursor: " + sequence.iterator().next());
    }
}
