import java.io.IOException;

public class Main {
    private static final class IndexReadException extends Exception {
        private IndexReadException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    private static void loadIndex() throws IndexReadException {
        try {
            throw new IOException("source unavailable");
        } catch (IOException cause) {
            throw new IndexReadException("index guide.md could not be loaded", cause);
        }
    }

    public static void main(String[] args) {
        try {
            loadIndex();
        } catch (IndexReadException exception) {
            System.out.println("error=index-read");
            System.out.println("message=" + exception.getMessage());
            System.out.println("cause=" + exception.getCause().getClass().getSimpleName());
        }
    }
}
