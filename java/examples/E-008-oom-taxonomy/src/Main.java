public class Main {
    static int spinDepth;

    static void spin() {
        spinDepth++;
        spin();
    }

    public static void main(String[] args) {
        try {
            int[] big = new int[Integer.MAX_VALUE];
            System.out.println("oom: allocated (unexpected)");
        } catch (OutOfMemoryError err) {
            System.out.println("oom-triggered: " + err.getClass().getName() + " caught");
            System.out.println("oom-kind: heap-exhaustion -> action=raise-heap-or-fix-leak");
        }

        try {
            spinDepth = 0;
            spin();
        } catch (StackOverflowError err) {
            System.out.println("soe-triggered: " + err.getClass().getName() + " caught");
            System.out.println("soe-kind: call-depth -> action=fix-recursion");
        }

        System.out.println("taxonomy: fatal errors are classified by trigger, not by message text");
    }
}
