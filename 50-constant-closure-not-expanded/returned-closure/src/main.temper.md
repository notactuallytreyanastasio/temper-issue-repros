# a function that returns a closure over its parameter, called with a constant

    let mk(start: Int): fn (): Int {
      fn (): Int { start + 1 }
    }
    let c = mk(3);
    console.log("${c()}");
