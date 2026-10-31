public class Main {
    private static int overwrittenReturn() {
        try {
            return 1;
        } finally {
            return 2;
        }
    }

    private static boolean swallowedException() {
        try {
            throw new IllegalStateException("original");
        } finally {
            return true;
        }
    }

    private static boolean cleanupRan;

    private static void preserveException() {
        try {
            throw new IllegalStateException("original");
        } finally {
            cleanupRan = true;
        }
    }

    public static void main(String[] args) {
        System.out.println("overwritten-return=" + overwrittenReturn());
        System.out.println("exception-swallowed=" + swallowedException());
        try {
            preserveException();
        } catch (IllegalStateException exception) {
            System.out.println("exception-preserved=" + exception.getClass().getSimpleName());
        }
        System.out.println("cleanup-ran=" + cleanupRan);
    }
}
