import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class Main {
    interface SortStrategy {
        List<String> sort(List<String> input);
    }

    static final class Alphabetical implements SortStrategy {
        @Override public List<String> sort(List<String> input) {
            List<String> result = new ArrayList<>(input);
            result.sort(Comparator.naturalOrder());
            return List.copyOf(result);
        }
    }

    static final class ByLength implements SortStrategy {
        @Override public List<String> sort(List<String> input) {
            List<String> result = new ArrayList<>(input);
            result.sort(Comparator.comparingInt(String::length)
                    .thenComparing(Comparator.naturalOrder()));
            return List.copyOf(result);
        }
    }

    static final class Sorter {
        private SortStrategy strategy;
        Sorter(SortStrategy strategy) { this.strategy = strategy; }
        void strategy(SortStrategy value) { strategy = value; }
        List<String> sort(List<String> input) { return strategy.sort(input); }
    }

    public static void main(String[] args) {
        List<String> input = List.of("pear", "fig", "apple", "kiwi");
        Sorter sorter = new Sorter(new Alphabetical());
        System.out.println("alphabetical: " + sorter.sort(input));
        sorter.strategy(new ByLength());
        System.out.println("by length: " + sorter.sort(input));
        System.out.println("input: " + input);
    }
}
