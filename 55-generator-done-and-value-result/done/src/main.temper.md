# Reading a generator's done

    let gen(body: fn (): SafeGenerator<Empty>): SafeGenerator<Empty> { body() }
    
    let g = gen { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("step");
      yield;
      console.log("last step");
    };
    console.log("before: ${g.done}");
    g.nextSafe();
    console.log("after one: ${g.done}");
    g.nextSafe();
    console.log("after two: ${g.done}");
