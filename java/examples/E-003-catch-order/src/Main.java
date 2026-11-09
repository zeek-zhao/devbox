import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InterruptedIOException;

public class Main {
    static String handleSpecific() {
        try {
            throw new FileNotFoundException("docs/7 missing");
        } catch (FileNotFoundException err) {
            return "FileNotFoundException caught: " + err.getMessage();
        }
    }

    static String handleParent() {
        try {
            throw new IOException("pipe broken");
        } catch (IOException err) {
            return "IOException caught: " + err.getMessage();
        }
    }

    static String handleUnion(boolean flag) {
        try {
            if (flag) {
                throw new FileNotFoundException("docs/7 missing");
            }
            throw new InterruptedIOException("read interrupted");
        } catch (FileNotFoundException | InterruptedIOException err) {
            return err.getClass().getSimpleName() + " caught by union handler";
        }
    }

    static String handleUnionThenParent(boolean flag) {
        try {
            if (flag) {
                throw new FileNotFoundException("docs/7 missing");
            }
            throw new IOException("pipe broken");
        } catch (FileNotFoundException | InterruptedIOException err) {
            return err.getClass().getSimpleName() + " caught by union handler";
        } catch (IOException err) {
            return "IOException caught by parent handler";
        }
    }

    public static void main(String[] args) {
        System.out.println("specific-first: " + handleSpecific());
        System.out.println("parent-catch: " + handleParent());
        System.out.println("union-catch: " + handleUnion(true));
        System.out.println("union-then-parent: " + handleUnionThenParent(false));
        System.out.println("order-rule: subclass handlers must precede their base class");
    }
}
