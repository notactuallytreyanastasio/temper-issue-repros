# Control: a list literal in an async block that does not await

    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let xs = [1, 2];
      console.log("${xs.length}");
    }
