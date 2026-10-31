final class Box {
    int value;

    Box(int value) {
        this.value = value;
    }
}

public class Main {
    private static void mutateAndReassign(Box box) {
        box.value = 8;
        box = new Box(99);
    }

    private static Box replacement(Box ignored) {
        return new Box(12);
    }

    public static void main(String[] args) {
        Box caller = new Box(7);
        mutateAndReassign(caller);
        System.out.println("caller value after parameter reassignment: " + caller.value);
        caller = replacement(caller);
        System.out.println("caller value after returned replacement: " + caller.value);
    }
}
