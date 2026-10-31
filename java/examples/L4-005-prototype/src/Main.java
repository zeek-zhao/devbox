import java.util.ArrayList;
import java.util.List;

public class Main {
    static final class Index {
        private static int initializations;
        private final List<String> terms;

        Index(List<String> terms) {
            initializations++;
            this.terms = new ArrayList<>(terms);
        }

        Index(Index prototype) {
            terms = new ArrayList<>(prototype.terms);
        }

        void add(String term) {
            terms.add(term);
        }

        String summary() {
            return terms.toString();
        }
    }

    public static void main(String[] args) {
        Index original = new Index(List.of("java", "patterns"));
        Index copy = new Index(original);
        System.out.println("different objects: " + (original != copy));
        System.out.println("different fields: " + (original.terms != copy.terms));
        copy.add("copy-only");
        System.out.println("original: " + original.summary());
        original.add("original-only");
        System.out.println("copy: " + copy.summary());
        System.out.println("initializations: " + Index.initializations);
    }
}
