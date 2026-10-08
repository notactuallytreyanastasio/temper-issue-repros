# A List from a call, not a literal, live across an await

    let p = new PromiseBuilder<Int>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let xs = "a,b".split(",");
      let x = await p.promise orelse -1;
      console.log("${x} ${xs.length}");
    }
    p.complete(3);
