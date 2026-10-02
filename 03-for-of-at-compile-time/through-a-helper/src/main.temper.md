# for-of, called through a helper that takes the test

    export let total(xs: List<Int>): Int {
      var t = 0;
      for (let x of xs) { t += x; }
      t
    }

    let totalIs(test: Test, xs: List<Int>, want: Int): Void {
      assert(total(xs) == want) { "wrong total" }
    }

    test("total adds") { test =>
      totalIs(test, [1, 2, 3], 6);
    }
