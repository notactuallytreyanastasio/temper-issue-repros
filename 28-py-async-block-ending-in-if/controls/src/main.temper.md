# Shapes that run on py: an else, or a statement after the if

    var n = 3;
    n = n + 0;
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      if (n > 0) { console.log("pos"); } else { console.log("neg"); }
    }
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      if (n > 0) { console.log("pos again"); }
      console.log("end");
    }
