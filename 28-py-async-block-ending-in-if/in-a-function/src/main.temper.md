# The same block inside a function

    let go(n: Int): Void {
      async { (): GeneratorResult<Empty> extends GeneratorFn =>
        if (n > 0) { console.log("pos"); }
      }
    }
    go(3);
