import devbox.rest.*;
// L2-011-jshell-experiments
Api api = Api.create();
if (api.handle(new Api.Request("POST", "/items", Json.name("REPL"))).status() != 201) throw new AssertionError("create");
if (!api.snapshot().getFirst().equals(new Api.Item(1, "REPL"))) throw new AssertionError("snapshot");
System.out.println("repl: ok");
/exit
