# for-of with no early exit

    export let total(xs: List<Int>): Int {
      var t = 0;
      for (let x of xs) { t += x; }
      t
    }

    console.log("total=${total([1, 2, 3])}");
