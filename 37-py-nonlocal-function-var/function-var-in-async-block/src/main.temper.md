# The same `var`, declared inside a top-level async block

    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      var f = fn (x: Int): Int { x };
      f = fn (x: Int): Int { x + 1 };
      console.log("${f(1)}");
    }
