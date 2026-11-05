import java.util.ArrayList;
import java.util.List;

/** T-001-deadlock-oom 被测程序二：无界分配把小堆打满 → OutOfMemoryError（类型②实验）。 */
public final class OomMain {

    private OomMain() {}

    public static void main(String[] args) {
        System.out.println("oom: start");
        List<byte[]> bag = new ArrayList<>();
        while (true) {
            // 每次 1 MB 且引用一直存活 —— 堆必然被打满，时间只由 -Xmx 决定。
            bag.add(new byte[1024 * 1024]);
        }
    }
}
