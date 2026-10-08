# An await inside a loop, on a promise completed after the block starts

    let later = new PromiseBuilder<String>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      for (var i = 0; i < 2; i += 1) {
        let s = await later.promise orelse "?";
        console.log("${s} ${i}");
      }
    }
    later.complete("same");
