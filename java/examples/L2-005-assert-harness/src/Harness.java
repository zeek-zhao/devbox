public final class Harness {
    private static int passed;
    private static int failed;

    private Harness() {}

    private static void run(String name, Runnable test) {
        try {
            test.run();
            passed++;
        } catch (AssertionError failure) {
            failed++;
        }
    }

    private static int execute(boolean injectFailure) {
        passed = 0;
        failed = 0;
        run(
                "addition",
                () -> {
                    assert 2 + 2 == 4;
                });
        run(
                "string",
                () -> {
                    assert "java".startsWith("j");
                });
        if (injectFailure) {
            run(
                    "injected",
                    () -> {
                        assert 1 == 2;
                    });
        } else {
            run(
                    "collection",
                    () -> {
                        assert java.util.List.of("a", "b").size() == 2;
                    });
        }
        System.out.println("passed: " + passed + " failed: " + failed);
        return failed == 0 ? 0 : 1;
    }

    public static void main(String[] args) {
        boolean assertionsEnabled = false;
        assert assertionsEnabled = true;
        if (!assertionsEnabled) {
            System.err.println("assertions-disabled");
            System.exit(2);
        }
        if (args.length == 1 && "direct".equals(args[0])) {
            assert false : "direct assertion";
            return;
        }
        boolean injectFailure = args.length == 1 && "injected".equals(args[0]);
        if (args.length > 1 || (args.length == 1 && !injectFailure)) {
            throw new IllegalArgumentException("unknown mode");
        }
        int exitCode = execute(injectFailure);
        if (exitCode != 0) {
            System.exit(exitCode);
        }
    }
}
