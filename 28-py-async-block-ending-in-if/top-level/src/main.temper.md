# An async block whose last statement is an if with no else

    var n = 3;
    n = n + 0;
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      if (n > 0) { console.log("pos"); }
    }
