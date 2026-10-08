# Testing a result with is ValueResult

    let gen(body: fn (): SafeGenerator<Int>): SafeGenerator<Int> { body() }
    
    let g = gen { (): GeneratorResult<Int> extends GeneratorFn =>
      yield 10;
      yield 20;
    };
    for (var i = 0; i < 3; i += 1) {
      let r = g.nextSafe();
      when (r) {
        is ValueResult<Int> -> console.log("value ${r.value}");
        else -> console.log("no value");
      }
    }
