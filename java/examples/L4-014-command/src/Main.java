import java.util.ArrayDeque;
import java.util.Deque;

public class Main {
    interface Command {
        void execute();

        void undo();
    }

    static final class Document {
        private String text;

        Document(String text) {
            this.text = text;
        }

        String text() {
            return text;
        }

        void replace(String value) {
            text = value;
        }
    }

    static final class ReplaceCommand implements Command {
        private final Document document;
        private final String replacement;
        private String previous;
        private boolean executed;

        ReplaceCommand(Document document, String replacement) {
            this.document = document;
            this.replacement = replacement;
        }

        @Override
        public void execute() {
            if (executed) {
                throw new IllegalStateException("Command already executed");
            }
            previous = document.text();
            document.replace(replacement);
            executed = true;
        }

        @Override
        public void undo() {
            if (!executed) {
                throw new IllegalStateException("Command not executed");
            }
            document.replace(previous);
            executed = false;
        }
    }

    static final class Editor {
        private final Deque<Command> history = new ArrayDeque<>();

        void submit(Command command) {
            command.execute();
            history.push(command);
        }

        void undo() {
            history.pop().undo();
        }
    }

    public static void main(String[] args) {
        Document document = new Document("draft");
        Editor editor = new Editor();
        String original = document.text();
        System.out.println("before: " + document.text());
        editor.submit(new ReplaceCommand(document, "review"));
        System.out.println("execute: " + document.text());
        editor.submit(new ReplaceCommand(document, "published"));
        System.out.println("execute: " + document.text());
        editor.undo();
        System.out.println("undo: " + document.text());
        editor.undo();
        System.out.println("undo: " + document.text());
        System.out.println("restored: " + original.equals(document.text()));
    }
}
