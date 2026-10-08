# Step 2: a class whose Java does not compile (#535), and a test that fails

    test("one passes") { test =>
      assert(1 + 1 == 2) { "arithmetic" }
    }

    export class Counter(public n: Int) {
      public sumTo(): Int {
        let go(i: Int): Int {
          if (i <= 0) { 0 } else { n + go(i - 1) }
        }
        go(3)
      }
    }

    test("two fails") { test =>
      assert(new Counter(1).sumTo() == 4) { "sumTo is 3, not 4" }
    }
