# three async blocks bump one counter

Each block adds 1 to the same field 3,000,000 times, so the field should end
at 9,000,000.

    class Counter {
      public var n: Int = 0;
      public bump(tag: String, times: Int): Void {
        for (var i = 0; i < times; ++i) {
          let before = n;
          n = before + 1;
        }
        console.log("${tag} done n=${n.toString()}");
      }
    }

    let c = new Counter();
    console.log("top start");
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("A start");
      c.bump("A", 3000000);
    }
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("B start");
      c.bump("B", 3000000);
    }
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      console.log("C start");
      c.bump("C", 3000000);
    }
    console.log("top end");
