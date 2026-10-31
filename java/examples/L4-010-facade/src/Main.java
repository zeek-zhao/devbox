import java.util.Arrays;
import java.util.List;

public class Main {
    static final class Parser {
        List<String> parse(String input) {
            List<String> terms = Arrays.asList(input.split(","));
            System.out.println("parse: " + terms);
            return terms;
        }
    }

    static final class Indexer {
        List<String> index(List<String> terms) {
            List<String> indexed = terms.stream().distinct().sorted().toList();
            System.out.println("index: " + indexed);
            return indexed;
        }
    }

    static final class Renderer {
        void render(List<String> indexed) {
            System.out.println("render: " + String.join("|", indexed));
        }
    }

    static final class SearchFacade {
        private final Parser parser = new Parser();
        private final Indexer indexer = new Indexer();
        private final Renderer renderer = new Renderer();

        void run(String input) {
            List<String> terms = parser.parse(input);
            List<String> indexed = indexer.index(terms);
            renderer.render(indexed);
        }
    }

    public static void main(String[] args) {
        new SearchFacade().run("patterns,java,java");
    }
}
