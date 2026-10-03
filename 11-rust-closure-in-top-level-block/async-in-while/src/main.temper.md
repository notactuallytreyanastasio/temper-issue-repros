# an `async` block inside a top-level `while` updates a top-level `var`

    var n = 0;
    var t = 0;
    while (t < 2) {
      async { (): GeneratorResult<Empty> extends GeneratorFn =>
        n += 1;
        console.log("n=${n}");
      }
      t += 1;
    }
