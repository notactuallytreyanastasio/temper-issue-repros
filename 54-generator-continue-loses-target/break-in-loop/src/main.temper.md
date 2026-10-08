# A break before a yield

    let gen(body: fn (): SafeGenerator<Empty>): SafeGenerator<Empty> { body() }
    
    let g = gen { (): GeneratorResult<Empty> extends GeneratorFn =>
      for (var i = 0; i < 3; i += 1) {
        if (i == 1) { console.log("break at ${i}"); break; }
        console.log("yield ${i}");
        yield();
      }
      console.log("done");
    };
    g.nextSafe();
    g.nextSafe();
