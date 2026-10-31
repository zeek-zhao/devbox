enum JobState {
    QUEUED(20),
    RUNNING(30),
    DONE(40);

    private final int code;

    JobState(int code) {
        this.code = code;
    }

    int code() {
        return code;
    }
}

public class Main {
    private static String describe(JobState state) {
        return switch (state) {
            case QUEUED -> "waiting";
            case RUNNING -> {
                String label = "active";
                yield label;
            }
            case DONE -> "finished";
        };
    }

    public static void main(String[] args) {
        JobState state = JobState.RUNNING;
        System.out.println("state code=" + state.code());
        System.out.println("state label=" + describe(state));
    }
}
