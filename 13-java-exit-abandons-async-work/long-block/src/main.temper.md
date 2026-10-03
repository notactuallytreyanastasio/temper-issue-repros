# An async block that runs for longer than ten seconds

    let rounds = 40;
    console.log("main: start");
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("block: start");
      var x = 1;
      for (var r = 0; r < rounds; ++r) {
        for (var i = 0; i < 100000000; ++i) {
          x = (x * 31 + i) % 1000003;
        }
      }
      console.log("block: done x=${x.toString()}");
    }
    console.log("main: end");
