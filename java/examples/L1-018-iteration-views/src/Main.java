import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

public class Main {
    private static boolean rejectsAdd(List<String> values) {
        try {
            values.add("blocked");
            return false;
        } catch (UnsupportedOperationException expected) {
            return true;
        }
    }

    public static void main(String[] args) {
        List<String> values = new ArrayList<>(List.of("c", "a", "b", "remove"));
        Iterator<String> iterator = values.iterator();
        while (iterator.hasNext()) {
            if (iterator.next().equals("remove")) {
                iterator.remove();
            }
        }
        values.sort(String::compareTo);

        List<String> view = Collections.unmodifiableList(values);
        List<String> snapshot = List.copyOf(values);
        values.add("later");

        System.out.println("sorted after iterator removal=" + values.subList(0, 3));
        System.out.println("view size after source change=" + view.size());
        System.out.println("snapshot size after source change=" + snapshot.size());
        System.out.println("view rejects add=" + rejectsAdd(view));
        System.out.println("snapshot rejects add=" + rejectsAdd(snapshot));
    }
}
