# a `let` assigned on only one branch

    export let f(b: Boolean): Int {
      let x: Int;
      if (b) { x = 1; }
      x
    }
