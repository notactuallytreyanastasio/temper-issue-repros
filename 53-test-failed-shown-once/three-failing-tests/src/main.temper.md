# Three tests that fail and one that passes

    test("first fails") { test =>
      assert(1 == 2) { "first message" }
    }

    test("second fails") { test =>
      assert(1 == 3) { "second message" }
    }

    test("third fails") { test =>
      assert(1 == 4) { "third message" }
    }

    test("fourth passes") { test =>
      assert(1 == 1) { "unreachable" }
    }
