# a block waits on a promise that top-level code completes

The block starts, prints, and waits on `g.promise`. Top-level code then
completes the promise, so the block should resume and print `resumed`.

    let g = new PromiseBuilder<Empty>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("waiting");
      await g.promise orelse void;
      console.log("resumed");
    }
    g.complete(empty());
    console.log("top level done");
