# for-of, never called at compile time

    export let total(xs: List<Int>): Int {
      var t = 0;
      for (let x of xs) { t += x; }
      t
    }
