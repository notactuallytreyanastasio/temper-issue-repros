# Code after complete() and the block it wakes

    let pb = new PromiseBuilder<Int>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("waiter: awaiting");
      let v = await pb.promise orelse -1;
      console.log("waiter: resumed with ${v}");
    }
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      // py and java start both blocks at once on a thread pool.
      // Spinning here lets the waiter reach its await first.
      var spin = 0;
      while (spin < 5000000) { spin += 1; }
      console.log("completer: calling complete");
      pb.complete(1);
      console.log("completer: complete returned");
    }
