public class Main {
    interface Implementor {
        String source();
    }

    static final class MemorySource implements Implementor {
        @Override
        public String source() {
            return "memory";
        }
    }

    static final class FileSource implements Implementor {
        @Override
        public String source() {
            return "file";
        }
    }

    abstract static class Report {
        protected final Implementor implementor;

        Report(Implementor implementor) {
            this.implementor = implementor;
        }

        abstract String render();
    }

    static final class TextReport extends Report {
        TextReport(Implementor implementor) {
            super(implementor);
        }

        @Override
        String render() {
            return "text/" + implementor.source();
        }
    }

    static final class JsonReport extends Report {
        JsonReport(Implementor implementor) {
            super(implementor);
        }

        @Override
        String render() {
            return "json/" + implementor.source();
        }
    }

    public static void main(String[] args) {
        Implementor memory = new MemorySource();
        Implementor file = new FileSource();
        Report[] reports = {
            new TextReport(memory), new TextReport(file),
            new JsonReport(memory), new JsonReport(file)
        };
        for (Report report : reports) {
            System.out.println(report.render());
        }
    }
}
