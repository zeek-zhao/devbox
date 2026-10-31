import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class Main {
    private record Document(String name, int pageCount, List<String> tags) {
        private Document {
            Objects.requireNonNull(name);
            if (pageCount < 0) {
                throw new IllegalArgumentException("pageCount must be non-negative");
            }
            tags = List.copyOf(tags);
        }
    }

    public static void main(String[] args) {
        List<String> sourceTags = new ArrayList<>(List.of("java", "guide"));
        Document first = new Document("guide.md", 3, sourceTags);
        Document same = new Document("guide.md", 3, List.of("java", "guide"));

        sourceTags.add("changed");
        System.out.println("equal=" + first.equals(same));
        System.out.println("same-hash=" + (first.hashCode() == same.hashCode()));
        System.out.println("tags-after-source-change=" + first.tags());
        try {
            new Document("invalid.md", -1, List.of());
        } catch (IllegalArgumentException exception) {
            System.out.println("negative-pages=" + exception.getClass().getSimpleName());
        }
    }
}
