import java.util.Objects;

public class Main {
    public static void main(String[] args) {
        String first = new String("query");
        String second = new String("query");
        System.out.println("same reference: " + (first == second));
        System.out.println("same content: " + first.equals(second));
        System.out.println("same hash: " + (first.hashCode() == second.hashCode()));
        System.out.println("null-safe same content: " + Objects.equals(first, second));
    }
}
