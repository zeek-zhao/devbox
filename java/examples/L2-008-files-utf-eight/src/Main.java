import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;

public class Main {
    public static void main(String[] args) throws IOException {
        Path directory = Path.of(args[0]);
        Path document = directory.resolve("document.txt");
        Path empty = directory.resolve("empty.txt");
        Path missing = directory.resolve("missing.txt");
        Files.createDirectories(directory);

        try {
            String text = "你好，世界";
            Files.writeString(document, text, StandardCharsets.UTF_8);
            System.out.println("utf8-roundtrip: " +
                    Files.readString(document, StandardCharsets.UTF_8));

            Files.writeString(empty, "", StandardCharsets.UTF_8);
            System.out.println("empty-length: " +
                    Files.readString(empty, StandardCharsets.UTF_8).length());

            try {
                Files.readString(missing, StandardCharsets.UTF_8);
                throw new IllegalStateException("missing file was accepted");
            } catch (NoSuchFileException expected) {
                System.out.println("missing-file: NoSuchFileException");
            }

            Files.delete(document);
            System.out.println("deleted: " + Files.exists(document));
        } finally {
            Files.deleteIfExists(document);
            Files.deleteIfExists(empty);
            Files.deleteIfExists(missing);
            Files.deleteIfExists(directory);
        }
    }
}
