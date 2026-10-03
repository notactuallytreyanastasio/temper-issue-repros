# An async block awaits a promise that nobody completes

    let pb = new PromiseBuilder<Int>();
    console.log("main: start");
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("block: awaiting");
      let v = await pb.promise orelse -1;
      console.log("block: resumed with ${v}");
    }
    console.log("main: end");
