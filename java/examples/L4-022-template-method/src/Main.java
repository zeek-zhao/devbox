public class Main {
    abstract static class Pipeline {
        final void run() {
            prepare();
            execute();
            verify();
        }

        abstract void prepare();
        abstract void execute();
        abstract void verify();
    }

    static final class MemoryPipeline extends Pipeline {
        @Override void prepare() { System.out.println("memory: prepare"); }
        @Override void execute() { System.out.println("memory: execute"); }
        @Override void verify() { System.out.println("memory: verify"); }
    }

    static final class FilePipeline extends Pipeline {
        @Override void prepare() { System.out.println("file: prepare"); }
        @Override void execute() { System.out.println("file: execute"); }
        @Override void verify() { System.out.println("file: verify"); }
    }

    public static void main(String[] args) {
        Pipeline[] pipelines = {new MemoryPipeline(), new FilePipeline()};
        for (Pipeline pipeline : pipelines) {
            pipeline.run();
        }
    }
}
