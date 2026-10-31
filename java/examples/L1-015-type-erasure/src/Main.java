import java.util.ArrayList;
import java.util.List;

public class Main {
    public static void main(String[] args) {
        List<String> words = new ArrayList<>();
        List<Integer> numbers = new ArrayList<>();
        System.out.println("same runtime class=" + (words.getClass() == numbers.getClass()));

        @SuppressWarnings({"rawtypes", "unchecked"})
        List raw = words;
        raw.add(7);
        boolean failedAtRead = false;
        try {
            String value = words.get(0);
            System.out.println("unexpected value=" + value);
        } catch (ClassCastException expected) {
            failedAtRead = true;
        }
        System.out.println("raw pollution fails at typed read=" + failedAtRead);
    }
}
