# shapes the frontend does reject

    export let never(): Int {
      let x: Int;
      x
    }

    export let viaVar(b: Boolean): Int {
      var y: Int;
      if (b) { y = 1; }
      y
    }

    export let notConstant(b: Boolean, n: Int): Int {
      let z: Int;
      if (b) { z = n; }
      z
    }
