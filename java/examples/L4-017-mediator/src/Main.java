import java.util.ArrayList;
import java.util.List;

public class Main {
    interface Mediator {
        void register(Colleague colleague);

        void send(Colleague sender, String message);
    }

    static final class Room implements Mediator {
        private final List<Colleague> colleagues = new ArrayList<>();

        @Override
        public void register(Colleague colleague) {
            colleagues.add(colleague);
        }

        @Override
        public void send(Colleague sender, String message) {
            if (!colleagues.contains(sender)) {
                throw new IllegalArgumentException("Sender is not registered");
            }
            for (Colleague colleague : colleagues) {
                if (colleague != sender) {
                    colleague.receive(sender.name(), message);
                }
            }
        }
    }

    static final class Colleague {
        private final String name;
        private final Mediator mediator;

        Colleague(String name, Mediator mediator) {
            this.name = name;
            this.mediator = mediator;
        }

        String name() {
            return name;
        }

        void send(String message) {
            mediator.send(this, message);
        }

        void receive(String sender, String message) {
            System.out.println(name + " <- " + sender + ": " + message);
        }
    }

    public static void main(String[] args) {
        Mediator room = new Room();
        Colleague alice = new Colleague("alice", room);
        Colleague bob = new Colleague("bob", room);
        Colleague carol = new Colleague("carol", room);
        room.register(alice);
        room.register(bob);
        room.register(carol);
        alice.send("hello");
        bob.send("ready");
    }
}
