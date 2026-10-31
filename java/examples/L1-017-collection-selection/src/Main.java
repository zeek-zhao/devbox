import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class Main {
    public static void main(String[] args) {
        List<String> indexed = new ArrayList<>(List.of("zero", "one", "two"));
        LinkedList<String> queue = new LinkedList<>(List.of("first", "second"));
        Map<String, Integer> lookup = new HashMap<>();
        lookup.put("alpha", 1);
        lookup.put("alpha", 2);

        TreeMap<String, Integer> ordered = new TreeMap<>();
        ordered.put("beta", 2);
        ordered.put("alpha", 1);

        System.out.println("array index 1=" + indexed.get(1));
        System.out.println("linked queue=" + queue.removeFirst() + "," + queue.getFirst());
        System.out.println("hash duplicate key=" + lookup.get(new String("alpha")));
        System.out.println("tree keys=" + ordered.keySet());
    }
}
