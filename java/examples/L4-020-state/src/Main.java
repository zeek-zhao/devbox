public class Main {
    interface State {
        String label();

        void advance(Task task);
    }

    static final class Pending implements State {
        @Override
        public String label() {
            return "pending: waiting";
        }

        @Override
        public void advance(Task task) {
            task.transition(new Running());
        }
    }

    static final class Running implements State {
        @Override
        public String label() {
            return "running: processing";
        }

        @Override
        public void advance(Task task) {
            task.transition(new Completed());
        }
    }

    static final class Completed implements State {
        @Override
        public String label() {
            return "completed: available";
        }

        @Override
        public void advance(Task task) {
            task.transition(this);
        }
    }

    static final class Task {
        private State state = new Pending();

        void transition(State next) {
            state = next;
        }

        void advance() {
            state.advance(this);
        }

        String describe() {
            return state.label();
        }
    }

    public static void main(String[] args) {
        Task task = new Task();
        System.out.println(task.describe());
        task.advance();
        System.out.println(task.describe());
        task.advance();
        System.out.println(task.describe());
        task.advance();
        System.out.println(task.describe());
    }
}
