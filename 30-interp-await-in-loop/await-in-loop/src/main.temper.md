# An await inside a loop

    let once = new PromiseBuilder<String>();
    once.complete("same");
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      for (var i = 0; i < 2; i += 1) {
        let s = await once.promise orelse "?";
        console.log("${s} ${i}");
      }
      let t = await once.promise orelse "?";
      console.log("${t} after the loop");
    }
