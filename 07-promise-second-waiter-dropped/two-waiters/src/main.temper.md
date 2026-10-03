# Two async blocks await one promise

    let pb = new PromiseBuilder<Int>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let v = await pb.promise orelse -1;
      console.log("first waiter got ${v}");
    }
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let v = await pb.promise orelse -1;
      console.log("second waiter got ${v}");
    }
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      pb.complete(7);
      console.log("completed");
    }
