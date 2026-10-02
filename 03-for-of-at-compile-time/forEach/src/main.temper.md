# the same loop written with forEach, called at compile time

    export let total(xs: List<Int>): Int {
      var t = 0;
      xs.forEach { (x): Void => t += x; };
      t
    }

    console.log("total=${total([1, 2, 3])}");
