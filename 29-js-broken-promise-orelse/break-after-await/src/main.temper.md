# Control: the promise is broken by a second async block, after the first has started awaiting

    let b = new PromiseBuilder<Int>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let v = await b.promise orelse -1;
      console.log("got ${v}");
    }
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      b.breakPromise();
    }
