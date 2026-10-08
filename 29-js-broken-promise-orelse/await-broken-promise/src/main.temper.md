# Awaiting a broken promise with orelse

    let b = new PromiseBuilder<Int>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let v = await b.promise orelse -1;
      console.log("got ${v}");
    }
    b.breakPromise();
