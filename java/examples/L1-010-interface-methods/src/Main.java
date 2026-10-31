interface LocalRules {
    default String validate() {
        return "local";
    }

    static String policy() {
        return "strict";
    }
}

interface SharedRules {
    default String validate() {
        return "shared";
    }
}

final class StoreService implements LocalRules, SharedRules {
    @Override
    public String validate() {
        return LocalRules.super.validate() + "+" + SharedRules.super.validate();
    }
}

public class Main {
    public static void main(String[] args) {
        StoreService service = new StoreService();
        System.out.println("resolved defaults: " + service.validate());
        System.out.println("interface static method: " + LocalRules.policy());
        boolean staticNotInherited;
        try {
            StoreService.class.getMethod("policy");
            staticNotInherited = false;
        } catch (NoSuchMethodException expected) {
            staticNotInherited = true;
        }
        System.out.println("implementation inherits static: " + !staticNotInherited);
    }
}
