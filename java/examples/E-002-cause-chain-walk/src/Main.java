import java.io.IOException;

public class Main {
    static final class StorageException extends RuntimeException {
        StorageException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    static final class ImportException extends RuntimeException {
        ImportException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    static void readDoc() throws IOException {
        throw new IOException("sector unreadable");
    }

    static void importDoc() {
        try {
            readDoc();
        } catch (IOException cause) {
            throw new StorageException("read path docs/7", cause);
        }
    }

    static Throwable rootCause(Throwable err) {
        Throwable root = err;
        while (root.getCause() != null && root.getCause() != root) {
            root = root.getCause();
        }
        return root;
    }

    static int chainDepth(Throwable err) {
        int depth = 1;
        for (Throwable cursor = err.getCause(); cursor != null; cursor = cursor.getCause()) {
            depth++;
        }
        return depth;
    }

    public static void main(String[] args) {
        try {
            try {
                importDoc();
            } catch (StorageException cause) {
                throw new ImportException("import doc-7 failed", cause);
            }
        } catch (ImportException err) {
            report(err);
        }
    }

    private static void report(ImportException err) {
        Throwable mid = err.getCause();
        Throwable root = rootCause(err);
        System.out.println("top: " + err.getClass().getSimpleName() + ": " + err.getMessage());
        System.out.println(
                "layer-2 cause: " + mid.getClass().getSimpleName() + ": " + mid.getMessage());
        System.out.println("root cause: " + root.getClass().getName() + ": " + root.getMessage());
        System.out.println("chain-depth: " + chainDepth(err));
        System.out.println("rule: wrap at boundaries, keep the cause, walk to the root");
    }
}
