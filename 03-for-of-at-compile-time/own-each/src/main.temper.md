# a block lambda that assigns an outer variable, called at compile time

    let each(xs: List<Int>, f: fn (Int): Void): Void {
      for (var i = 0; i < xs.length; ++i) { f(xs[i]); }
    }

    export let total(xs: List<Int>): Int {
      var t = 0;
      each(xs) { (x: Int): Void => t += x; };
      t
    }

    console.log("total=${total([1, 2, 3])}");
