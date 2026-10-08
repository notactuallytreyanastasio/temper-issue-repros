# A condition right after a bare yield

    let gen(body: fn (): SafeGenerator<Empty>): SafeGenerator<Empty> { body() }

    let g = gen { (): GeneratorResult<Empty> extends GeneratorFn =>
      for (var i = 0; i < 4; i += 1) {
        console.log("at ${i}");
        yield;
        if (i == 1) { console.log("break at ${i}"); break; }
      }
      console.log("out");
    };
    g.nextSafe();
    g.nextSafe();
    g.nextSafe();
    g.nextSafe();
