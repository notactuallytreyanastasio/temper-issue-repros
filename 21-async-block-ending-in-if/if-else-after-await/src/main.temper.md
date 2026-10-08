# An async block that ends in if/else after an await

    let p = new PromiseBuilder<Int>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let v = await p.promise orelse -1;
      if (v < 0) { console.log("neg"); } else { console.log("pos"); }
    }
    p.complete(3);
