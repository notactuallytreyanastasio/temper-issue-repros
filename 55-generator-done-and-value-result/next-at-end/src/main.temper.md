# Calling nextSafe on the step that finishes, and after

    let gen(body: fn (): SafeGenerator<Empty>): SafeGenerator<Empty> { body() }
    
    let g = gen { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("first step");
      yield;
      console.log("last step");
    };
    g.nextSafe();
    console.log("one call");
    g.nextSafe();
    console.log("two calls");
    g.nextSafe();
    console.log("three calls");
