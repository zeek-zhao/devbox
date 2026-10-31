import java.util.HashMap;

public class Main {
    static final class Token {
        private static int constructions;
        private final String text;

        Token(String text) {
            constructions++;
            this.text = text;
        }

        String render(int line, int column) {
            return text + "@" + line + ":" + column;
        }
    }

    static final class TokenFactory {
        private final HashMap<String, Token> cache = new HashMap<>();

        Token get(String text) {
            return cache.computeIfAbsent(text, Token::new);
        }
    }

    public static void main(String[] args) {
        TokenFactory factory = new TokenFactory();
        Token first = factory.get("java");
        Token second = factory.get(new String("java"));
        Token other = factory.get("patterns");
        System.out.println("same key: " + (first == second));
        System.out.println("different key: " + (first != other));
        System.out.println(first.render(1, 2));
        System.out.println(second.render(3, 4));
        System.out.println(other.render(5, 6));
        System.out.println("constructions: " + Token.constructions);
    }
}
