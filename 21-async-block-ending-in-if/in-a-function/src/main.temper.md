# The same shape in an async block inside a function

    let go(n: Int): Void {
      async { (): GeneratorResult<Empty> extends GeneratorFn =>
        let p = new PromiseBuilder<Int>();
        p.complete(n);
        let v = await p.promise orelse -1;
        if (v < 0) {
          console.log("neg");
        } else {
          console.log("pos ${v}");
        }
      }
    }
    var n = 3;
    n = n;
    go(n);
