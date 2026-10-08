# A list literal in an async block that awaits

    let p = new PromiseBuilder<Int>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let xs = [1, 2];
      let x = await p.promise orelse -1;
      console.log("${x} ${xs.length}");
    }
    p.complete(3);
