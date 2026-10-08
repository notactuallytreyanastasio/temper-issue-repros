# A continue that skips a yield

    let gen(body: fn (): SafeGenerator<Empty>): SafeGenerator<Empty> { body() }
    
    let g = gen { (): GeneratorResult<Empty> extends GeneratorFn =>
      for (var i = 0; i < 3; i += 1) {
        if (i == 1) { console.log("skip ${i}"); continue; }
        console.log("yield ${i}");
        yield();
      }
      console.log("done");
    };
    g.nextSafe();
    g.nextSafe();
    g.nextSafe();
