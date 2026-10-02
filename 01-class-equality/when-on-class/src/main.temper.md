# `when` over a class's static instances

    export class Space(public name: String) {
      public static a = new Space("a");
      public static b = new Space("b");
    }

    export let describe(s: Space): String {
      when (s) {
        Space.a -> "first";
        Space.b -> "second";
        else -> "other";
      }
    }

    let check(test: Test, got: String, want: String): Void {
      assert(got == want) { "got ${got}, want ${want}" }
    }

    test("when picks the matching instance") { test =>
      check(test, describe(Space.b), "second");
    }
